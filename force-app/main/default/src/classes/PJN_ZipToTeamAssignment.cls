/**
 * @author Mavens
 * @date Feb 2019
 * @description Assign Care Team to Care Plan on care plan creation and on update of the Physician.
 *   - On Care Plan Creation copy over Care Team defined in the PJN_Zip_To_Team__c object.
 *      Search by (zip+country+program) key.
 *      The address used is the one selected during Enrollment and stored as a Lookup to the
 *      Contact Information object in the field "Enrollment Address" in the Care Plan.
 *      If no Physician, then take patient primary address.
 *          + OwnerId
 * @group ZipToTeam
 */
public with sharing class PJN_ZipToTeamAssignment implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        Set<Id> enrollmentContactInformationIds = new Set<Id>();
        Set<Id> patientIds = new Set<Id>();
        Map<Id, List<Case>> carePlansToProcessByAccountId = getCarePlansToProcessByAccountId(enrollmentContactInformationIds, patientIds);
        if (!carePlansToProcessByAccountId.isEmpty()) {
            List<PJN_Contact_Information__c> contactInformation = getContactInformation(patientIds, enrollmentContactInformationIds);
            Set<String> externalIds = new Set<String>();
            Map<Id, Map<String,String>> externalIdByAccountId = buildExternalIds(contactInformation, carePlansToProcessByAccountId, externalIds);
            Map<String, PJN_Zip_To_Team__c> zipToTeamByExternalId = getZipToTeamInformation(externalIds);
            assignCarePlanToCareTeam(carePlansToProcessByAccountId, externalIdByAccountId, zipToTeamByExternalId);
        }
    }

    /**
     * Get new Care Plan created or those that have changed their Physician
     * @returns   Map of Care Plan Cases to process by Account Id (Account would be Physician or patient)
     */
    private Map<Id, List<Case>> getCarePlansToProcessByAccountId(Set<Id> enrollmentContactInformationIds, Set<Id> patientIds) {
        Map<Id, List<Case>> carePlansToProcessByAccountId = new Map<Id, List<Case>>();
        Id carePlanRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId();
        if (Trigger.isInsert) {
            for (Case currentCase : (List<Case>) Trigger.new) {
                if (currentCase.RecordTypeId == carePlanRecordTypeId) {
                    if (currentCase.PJN_Physician__c != null && currentCase.PJN_Enrollment_Address__c != null) {
                        if (!carePlansToProcessByAccountId.containsKey(currentCase.PJN_Physician__c)) {
                            carePlansToProcessByAccountId.put(currentCase.PJN_Physician__c, new List<Case>());
                        }
                        carePlansToProcessByAccountId.get(currentCase.PJN_Physician__c).add(currentCase);
                        enrollmentContactInformationIds.add(currentCase.PJN_Enrollment_Address__c);
                    } else if (currentCase.AccountId != null) {
                        if (!carePlansToProcessByAccountId.containsKey(currentCase.AccountId)) {
                            carePlansToProcessByAccountId.put(currentCase.AccountId, new List<Case>());
                        }
                        carePlansToProcessByAccountId.get(currentCase.AccountId).add(currentCase);
                        patientIds.add(currentCase.AccountId);
                    }
                }
            }
        } else if (Trigger.isUpdate) {
            for (Id caseId : Trigger.newMap.keySet()) {
                Case oldCase = (Case) Trigger.oldMap.get(caseId);
                Case currentCase = (Case) Trigger.newMap.get(caseId);
                if (currentCase.RecordTypeId == carePlanRecordTypeId &&
                    (oldCase.PJN_Physician__c != currentCase.PJN_Physician__c || currentCase.PJN_Run_ZTT_Against_Enrollment_Address__c == true)){
                    if (currentCase.PJN_Physician__c != null) {
                        if (!carePlansToProcessByAccountId.containsKey(currentCase.PJN_Physician__c)) {
                            carePlansToProcessByAccountId.put(currentCase.PJN_Physician__c, new List<Case>());
                        }
                        carePlansToProcessByAccountId.get(currentCase.PJN_Physician__c).add(currentCase);
                        patientIds.add(currentCase.PJN_Physician__c);
                    } else if (currentCase.AccountId != null) {
                        if (!carePlansToProcessByAccountId.containsKey(currentCase.AccountId)) {
                            carePlansToProcessByAccountId.put(currentCase.AccountId, new List<Case>());
                        }
                        carePlansToProcessByAccountId.get(currentCase.AccountId).add(currentCase);
                        patientIds.add(currentCase.AccountId);
                    }
                }
            }
        }
        return carePlansToProcessByAccountId;
    }

    /**
     * Get Contact Information records for patients and Physicians
     * @param  patientIds                       Set of Account Ids
     * @param  enrollmentContactInformationIds  Set of Contact Information Ids
     * @returns                                  List of Contact Information
     */
    private List<PJN_Contact_Information__c> getContactInformation(Set<Id> patientIds, Set<Id> enrollmentContactInformationIds) {
        List<PJN_Contact_Information__c> contactInformationPatient = getPatientContactInformation(patientIds);
        List<PJN_Contact_Information__c> contactInformationPhysician = getPhysicianContactInformation(enrollmentContactInformationIds);
        List<PJN_Contact_Information__c> contactInformation = new List<PJN_Contact_Information__c>();
        contactInformation.addAll(contactInformationPatient);
        contactInformation.addAll(contactInformationPhysician);
        return contactInformation;
    }

    /**
     * Get Contact Information records that are primary and with record type PJN_Address for a
     * list of account ids
     * @param  accountIds Set of Account Ids
     * @returns            List of Contact Information
     */
    private List<PJN_Contact_Information__c> getPatientContactInformation(Set<Id> accountIds) {
        return [
            SELECT
                PJN_Account__c,
                PJN_Postal_Code__c,
                PJN_Country__c
            FROM
                PJN_Contact_Information__c
            WHERE
                RecordTypeId = :Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
            AND
                PJN_Account__c IN :accountIds
            AND
                PJN_Primary__c = true
        ];
    }

    /**
     * Get Contact Information records for a list of contact information ids
     * @param  accountIds Set of Account Ids
     * @returns            List of Contact Information
     */
    private List<PJN_Contact_Information__c> getPhysicianContactInformation(Set<Id> contactInformationIds) {
        return [
            SELECT
                PJN_Account__c,
                PJN_Postal_Code__c,
                PJN_Country__c
            FROM
                PJN_Contact_Information__c
            WHERE
                Id IN :contactInformationIds
        ];
    }

    /**
     * Build external ids to query the Zip_To_Team__c object:
     *   External Id = Physician_primary_address.zip_code + '_' + Physician_primary_address_country + '_' + program_developer_name
     *   (If there is no Physician, then it would be patient_primary_address
     * @returns   Map of external ids for zip_to_team__c by account id
     */
    private Map<Id, Map<String, String>> buildExternalIds(List<PJN_Contact_Information__c> contactInformation,
                                            Map<Id, List<Case>> carePlansToProcessByAccountId,
                                            Set<String> externalIds) {

        Map<Id, Map<String, String>> externalIdsMap = new Map<Id, Map<String, String>>();
        for (PJN_Contact_Information__c address : contactInformation) {
            String postalCode = address.PJN_Postal_Code__c;
            if (postalCode != null && postalCode.length()>=5) {
                postalCode = postalCode.substring(0,5);
            }
            externalIdsMap.put(address.PJN_Account__c, new Map<String, String>());
            for (Case currentCase : carePlansToProcessByAccountId.get(address.PJN_Account__c)) {
                String externalId = postalCode + '_' +
                                    address.PJN_Country__c + '_' +
                                    currentCase.PJN_Program_DeveloperName__c;
                externalIdsMap.get(address.PJN_Account__c).put(currentCase.PJN_Program_DeveloperName__c, externalId);
                externalIds.add(externalId);
            }
        }
        return externalIdsMap;
    }

    /**
     * Get Zip To Team records by external ids
     * @param  externalIds Set of external ids to run the query
     * @returns             Map of Zip To Team records by external id
     */
    private Map<String, PJN_Zip_To_Team__c> getZipToTeamInformation(Set<String> externalIds) {
        List<PJN_Zip_To_Team__c> zipToTeamList = [
            SELECT
                PJN_Case_Manager__c,
                PJN_External_ID__c,
                MVN_Sales_Name__c,
                MVN_Sales_Email__c,
                MVN_RBM_TerrName__c,
                MVN_RBM_Director_Name__c,
                MVN_RBM_Director_Email__c,
                MVN_National_Sales_Director_Name__c,
                MVN_National_Sales_Director_Email__c,
                MVN_RD_Name__c,
                MVN_RD_Email__c
            FROM
                PJN_Zip_To_Team__c
            WHERE
                PJN_External_ID__c = :externalIds
        ];
        Map<String, PJN_Zip_To_Team__c> zipToTeamByExternalId = new Map<String, PJN_Zip_To_Team__c>();
        for (PJN_Zip_To_Team__c zipToTeam :zipToTeamList) {
            zipToTeamByExternalId.put(zipToTeam.PJN_External_ID__c, zipToTeam);
        }
        return zipToTeamByExternalId;
    }

    /**
     * Copy the information stored in the Zip To Team table to the Care Plan:
     *     + OwnerId - PJN_Case_Manager__c
     */
    private void assignCarePlanToCareTeam(Map<Id, List<Case>> carePlansToProcessByAccountId,
                                            Map<Id, Map<String, String>> externalIdByAccountId,
                                            Map<String, PJN_Zip_To_Team__c> zipToTeamByExternalId) {

        List<Case> casesToMap = new List<Case>();
        List<Id> sourceObjectIds = new List<Id>();
        for (Id accountId : carePlansToProcessByAccountId.keySet()) {
            for (Case currentCase : carePlansToProcessByAccountId.get(accountId)) {
                Map<String, String> externalIdByProgram = externalIdByAccountId.get(accountId);
                if (externalIdByProgram == null) {
                    continue;
                }
                String externalId = externalIdByProgram.get(currentCase.PJN_Program_DeveloperName__c);
                PJN_Zip_To_Team__c zipToTeam = zipToTeamByExternalId.get(externalId);
                if (zipToTeam == null) {
                    continue;
                }

                if ((Trigger.isInsert || currentCase.PJN_Run_ZTT_Against_Enrollment_Address__c == true)
                    && zipToTeam.PJN_Case_Manager__c != null) {
                    currentCase.OwnerId = zipToTeam.PJN_Case_Manager__c;
                }
                casesToMap.add(currentCase);
                sourceObjectIds.add(zipToTeam.Id);
                currentCase.PJN_Zip_To_Team__c = zipToTeam.Id;
                currentCase.PJN_Run_ZTT_Against_Enrollment_Address__c = false;
                currentCase.MVN_Sales_Name__c  = zipToTeam.MVN_Sales_Name__c;
                currentCase.MVN_Sales_Email__c = zipToTeam.MVN_Sales_Email__c;
                currentCase.MVN_RBM_TerrName__c  = zipToTeam.MVN_RBM_TerrName__c;
                currentCase.MVN_Case_RBM_Director_Name__c = zipToTeam.MVN_RBM_Director_Name__c;
                currentCase.MVN_Case_RBM_Director_Email__c = zipToTeam.MVN_RBM_Director_Email__c;
                currentCase.MVN_Case_National_Sales_Director_Name__c = zipToTeam.MVN_National_Sales_Director_Name__c;
                currentCase.MVN_Case_National_Sales_Director_Email__c = zipToTeam.MVN_National_Sales_Director_Email__c;
                currentCase.MVN_Case_RD_Name__c = zipToTeam.MVN_RD_Name__c;
                currentCase.MVN_Case_RD_Email__c = zipToTeam.MVN_RD_Email__c;
            }
        }
        if (!casesToMap.isEmpty()) {
            PJN_MappingEngine mappingEngine = new PJN_MappingEngine();
            mappingEngine.initiate('PJN_Care_Team_Mapping');
            mappingEngine.run(
                new Map<String, List<Id>> { 'zipToTeam' => sourceObjectIds },
                casesToMap
            );
        }
    }
}