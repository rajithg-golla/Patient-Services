/**
 * @author      Mavens
 * @group       ZipToTeam
 * @description Scheduler batch job of Zip To team Reassignment.
 *              Search by (zip+country+program) key.
 *              The address used is the one selected during Enrollment and stored as a Lookup to the
 *                  Contact Information object in the field "Enrollment Address" in the Care Plan.
 *              If no Physician, then take patient primary address.
 */
public with sharing class MVN_ZipToTeamAssignmentBatchSch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    /**
     * Schedule execute method which will execute the Zip to team reassignment
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        MVN_ZipToTeamAssignmentBatchSch zttAssignmentBatch = new MVN_ZipToTeamAssignmentBatchSch();
        ID batchprocessid = Database.executeBatch(zttAssignmentBatch, 2000);
    }

    /**
     * Start batch job querying all CarePlans to be reassigned
     * @param BC    Batch Context
     * @return  `Database.QueryLocator`
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    AccountId,
                    PJN_Physician__c,
                    PJN_Enrollment_Address__c,
                    PJN_Enrollment_Address__r.PJN_Account__c,
                    PJN_Run_ZTT_Against_Enrollment_Address__c,
                    PJN_Program_DeveloperName__c,
                    MVN_Case_RBM_Director_Name__c,
                    MVN_Case_RBM_Director_Email__c,
                    MVN_Case_National_Sales_Director_Name__c,
                    MVN_Case_National_Sales_Director_Email__c,
                    MVN_Case_RD_Name__c,
                    MVN_Case_RD_Email__c
                FROM
                    Case
                WHERE
                    RecordType.DeveloperName = 'CarePlan' 
            ]
        );
    }

    /**
     * Execute batch job reassigning the CarePlans to the correct Zip To Team
     * @param BC    Batch Context
     * @param scope CarePlans to be reassigned
     */
    public void execute(Database.BatchableContext BC, List<Case> scope) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> enrollmentContactInformationIds = new Set<Id>();
        Map<Id, List<Case>> carePlansToProcessByAccountId = new Map<Id, List<Case>>();
        for (Case thisCase : scope) {
            if (thisCase.PJN_Physician__c != null) {
                if (!carePlansToProcessByAccountId.containsKey(thisCase.PJN_Physician__c)) {
                    carePlansToProcessByAccountId.put(thisCase.PJN_Physician__c, new List<Case>());
                }
                carePlansToProcessByAccountId.get(thisCase.PJN_Physician__c).add(thisCase);
                if (thisCase.PJN_Enrollment_Address__c != null && thisCase.PJN_Enrollment_Address__r.PJN_Account__c == thisCase.PJN_Physician__c) {
                    enrollmentContactInformationIds.add(thisCase.PJN_Enrollment_Address__c);
                } else {
                    accountIds.add(thisCase.PJN_Physician__c);
                }
            } else if (thisCase.AccountId != null) {
                if (!carePlansToProcessByAccountId.containsKey(thisCase.AccountId)) {
                    carePlansToProcessByAccountId.put(thisCase.AccountId, new List<Case>());
                }
                carePlansToProcessByAccountId.get(thisCase.AccountId).add(thisCase);
                accountIds.add(thisCase.AccountId);
            }
        }
        List<PJN_Contact_Information__c> contactInformations = getContactInformations(enrollmentContactInformationIds, accountIds);
        Set<String> externalIds = new Set<String>();
        Map<Id, Map<String,String>> externalIdByAccountId = buildExternalIds(contactInformations, carePlansToProcessByAccountId, externalIds);
        Map<String, PJN_Zip_To_Team__c> zipToTeamByExternalId = getZipToTeamInformation(externalIds);
        assignCarePlanToCareTeam(carePlansToProcessByAccountId, externalIdByAccountId, zipToTeamByExternalId);
    }

    /**
     * Get Contact Information records for patients and Physicians
     * @param enrollmentContactInformationIds   Set of Contact Information Ids
     * @param accountIds                        Set of Account Ids
     * @return  `List<PJN_Contact_Information__c>`
     */
    private List<PJN_Contact_Information__c> getContactInformations(Set<Id> enrollmentContactInformationIds, Set<Id> accountIds) {
        return [
            SELECT
                PJN_Account__c,
                PJN_Postal_Code__c,
                PJN_Country__c
            FROM
                PJN_Contact_Information__c
            WHERE
                (
                    Id IN :enrollmentContactInformationIds
                )
                OR
                (
                    RecordTypeId = :Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
                AND
                    PJN_Account__c IN :accountIds
                AND
                    PJN_Primary__c = true
                )
        ];
    }

    /**
     * Build external ids to query the Zip_To_Team__c object:
     *   External Id = Physician_primary_address.zip_code + '_' + Physician_primary_address_country + '_' + program_developer_name
     *   (If there is no Physician, then it would be patient_primary_address
     * @param contactInformations           List of contact informations to build the ext id
     * @param carePlansToProcessByAccountId Map of care plans by patient/physician
     * @param externalIds                   External Ids
     * @return  `Map<Id, Map<String, String>>`
     */
    private Map<Id, Map<String, String>> buildExternalIds(List<PJN_Contact_Information__c> contactInformations,
                                            Map<Id, List<Case>> carePlansToProcessByAccountId,
                                            Set<String> externalIds) {

        Map<Id, Map<String, String>> externalIdsMap = new Map<Id, Map<String, String>>();
        for (PJN_Contact_Information__c address : contactInformations) {
            String postalCode = address.PJN_Postal_Code__c;
            if (postalCode != null && postalCode.length()>=5) {
                postalCode = postalCode.substring(0,5);
            }
            externalIdsMap.put(address.PJN_Account__c, new Map<String, String>());
            for (Case thisCase : carePlansToProcessByAccountId.get(address.PJN_Account__c)) {
                String externalId = postalCode + '_' +
                                    address.PJN_Country__c + '_' +
                                    thisCase.PJN_Program_DeveloperName__c;
                externalIdsMap.get(address.PJN_Account__c).put(thisCase.PJN_Program_DeveloperName__c, externalId);
                externalIds.add(externalId);
            }
        }
        return externalIdsMap;
    }

    /**
     * Get Zip To Team records by external ids
     * @param externalIds   Set of external ids to run the query
     * @return  `Map<String, PJN_Zip_To_Team__c>`
     */
    private Map<String, PJN_Zip_To_Team__c> getZipToTeamInformation(Set<String> externalIds) {
        List<PJN_Zip_To_Team__c> zipToTeamList = [
            SELECT
                Id,
                PJN_External_ID__c,
                PJN_Region__c,
                PJN_Territory__c,
                MVN_RBM_User__c,
                MVN_RBM_TerrName__c, 
                MVN_Sales_Name__c,
                MVN_Sales_Email__c,
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
     * @param carePlansToProcessByAccountId Map of CarePlans by Patient/Physician
     * @param externalIdByAccountId         ZTT External Id by Patient/Physician
     * @param zipToTeamByExternalId         Zip to Team record by ZTT External Id
     */
    private void assignCarePlanToCareTeam(Map<Id, List<Case>> carePlansToProcessByAccountId,
                                            Map<Id, Map<String, String>> externalIdByAccountId,
                                            Map<String, PJN_Zip_To_Team__c> zipToTeamByExternalId) {

        List<Case> casesToMap = new List<Case>();
        List<Id> sourceObjectIds = new List<Id>();
        for (Id accountId : carePlansToProcessByAccountId.keySet()) {
            for (Case thisCase : carePlansToProcessByAccountId.get(accountId)) {
                Map<String, String> externalIdByProgram = externalIdByAccountId.get(accountId);
                if (externalIdByProgram == null) {
                    continue;
                }
                String externalId = externalIdByProgram.get(thisCase.PJN_Program_DeveloperName__c);
                PJN_Zip_To_Team__c zipToTeam = zipToTeamByExternalId.get(externalId);
                if (zipToTeam == null) {
                    continue;
                }

                thisCase.PJN_Zip_To_Team__c = zipToTeam.Id;
                thisCase.PJN_Run_ZTT_Against_Enrollment_Address__c = false;
                thisCase.PJN_Region__c = zipToTeam.PJN_Region__c;
                thisCase.PJN_Territory__c = zipToTeam.PJN_Territory__c;
                thisCase.MVN_RBM_User__c = zipToTeam.MVN_RBM_User__c;
                thisCase.MVN_RBM_TerrName__c = zipToTeam.MVN_RBM_TerrName__c;
                thisCase.MVN_Sales_Name__c  = zipToTeam.MVN_Sales_Name__c;
                thisCase.MVN_Sales_Email__c = zipToTeam.MVN_Sales_Email__c;
                thisCase.MVN_Case_RBM_Director_Name__c = zipToTeam.MVN_RBM_Director_Name__c;
                thisCase.MVN_Case_RBM_Director_Email__c = zipToTeam.MVN_RBM_Director_Email__c;
                thisCase.MVN_Case_National_Sales_Director_Name__c = zipToTeam.MVN_National_Sales_Director_Name__c;
                thisCase.MVN_Case_National_Sales_Director_Email__c = zipToTeam.MVN_National_Sales_Director_Email__c;
                thisCase.MVN_Case_RD_Name__c = zipToTeam.MVN_RD_Name__c;
                thisCase.MVN_Case_RD_Email__c = zipToTeam.MVN_RD_Email__c;
                casesToMap.add(thisCase);
                sourceObjectIds.add(zipToTeam.Id);
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
        update casesToMap;
    }

    /**
     * Finish batch job method
     * @param BC
     */
    public void finish(Database.BatchableContext BC) {
    }
}