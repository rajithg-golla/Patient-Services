/**
 * @author      Mavens
 * @date        June 30, 2021
 * @description Batch job that converts medical Staging Claims to Claims.
 */
public with sharing class MVN_StagingConvertMedical implements Schedulable, Database.Batchable<sObject> {

    /**
     * Schedule execute method which will start batch job
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        Id batchJobId = Database.executeBatch(new MVN_StagingConvertMedical(), 200);
    }

    /**
     * Collect the records or objects to pass to the interface method execute.
     * @param bc
     * @returns `Database.QueryLocator`
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // build the query
        String query = buildStagingClaimQueryString();

        // return the query locator
        return Database.getQueryLocator(query);
    }

    /**
     * Processing for each chunk of data.
     * @param bc
     * @param scope
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<MVN_Staging_Claim__c> stagingClaims = (List<MVN_Staging_Claim__c>) scope;
        Set<String> memberIds = new Set<String>();
        Set<String> datesOfService = new Set<String>();
        
        
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            if (String.isNotBlank(stagingClaim.MVN_Member_Id__c)) {
                memberIds.add(stagingClaim.MVN_Member_Id__c);
            }
            
            stagingClaim.MVN_Date_of_Service__c = formatDateOfService(stagingClaim.MVN_Date_of_Service__c);

            if (String.isNotBlank(stagingClaim.MVN_Date_of_Service__c)) {
                datesOfService.add(stagingClaim.MVN_Date_of_Service__c);
            }
        }

        // Maps necessary for populating claim
        Map<String, Map<String, MVN_Claim__c>> claimMap = queryClaimMap(memberIds, datesOfService);
        Map<String, PJN_Assistance_Program__c> memberIdToAssistanceProgramMap = queryAssistanceProgramMap(memberIds);

        // Objects that for DML transaction
        Map<Id, MVN_Claim__c> claimsToUpdate = new Map<Id, MVN_Claim__c>();
        List<MVN_Claim__c> claimsToInsert = new List<MVN_Claim__c>();
        List<MVN_Staging_Claim__c> stagingClaimsForUpdate = new List<MVN_Staging_Claim__c>();

        // Loop through Staging Claims and build Claims and edit Staging Claims
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            // Claim match found by Member Id and Date of Service, build claim
            if (
                claimMap.containsKey(stagingClaim.MVN_Member_Id__c) && 
                claimMap.get(stagingClaim.MVN_Member_Id__c).containsKey(stagingClaim.MVN_Date_of_Service__c)
            ) {
                MVN_Claim__c claim = buildClaim(
                    stagingClaim, 
                    claimMap.get(stagingClaim.MVN_Member_Id__c).get(stagingClaim.MVN_Date_of_Service__c)
                );

                if (claim.Id != null) {
                    claimsToUpdate.put(claim.Id, claim);
                } else {
                    claimsToInsert.add(claim);
                }

                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Complete;
                stagingClaim.MVN_Error_Message__c = '';

            // Assistance Progam match found by Member Id, build claim
            } else if (String.isNotBlank(stagingClaim.MVN_Member_Id__c) && memberIdToAssistanceProgramMap.containsKey(stagingClaim.MVN_Member_Id__c)) {
                MVN_Claim__c claim = buildClaim(stagingClaim);
                claim.MVN_Copay_Assistance_Program__c = memberIdToAssistanceProgramMap.get(stagingClaim.MVN_Member_Id__c).Id;
                claim.MVN_Care_Plan__c = memberIdToAssistanceProgramMap.get(stagingClaim.MVN_Member_Id__c).PJN_Care_Plan__c;
                claimsToInsert.add(claim);
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Complete;
                stagingClaim.MVN_Error_Message__c = '';

            // Member Id is blank, match impossible
            } else if (String.isBlank(stagingClaim.MVN_Member_Id__c)) {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Member_Id_is_Blank;

            // Generic no match found error
            } else {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Copay_Not_Found;
            }
            stagingClaimsForUpdate.add(stagingClaim);
        }

        // Perform DML
        List<MVN_Claim__c> claimsToUpsert = claimsToInsert;
        claimsToUpsert.addAll(claimsToUpdate.values());

        upsert claimsToUpsert;
        update stagingClaimsForUpdate;

        createActivities(claimsToUpsert);

    }

    /**
     * Finish method.
     * @param bc
     */
    public void finish(Database.BatchableContext bc) { //NOPMD
    }

    /**
     * @description Remove any leading '0' number for days and months in the String date to match Salesforce format
     * @param  dateOfService String Date Of Service
     * @return Strin
     */
    private String formatDateOfService(String dateOfService) {
        if (dateOfService == null) {
            return dateOfService;
        }
        List<String> dateSplit = dateOfService.split('/');
        return dateSplit[0].removeStart('0') + '/' + dateSplit[1].removeStart('0') + '/' + dateSplit[2];
    }


    /**
     * Build a Claim based on Staging Claim and old Claim.
     * @param stagingClaim
     * @param oldClaim
     * @return  `MVN_Claim__c`
     */
    private MVN_Claim__c buildClaim(MVN_Staging_Claim__c stagingClaim, MVN_Claim__c oldClaim) {

        Id recordTypeId = Schema.SObjectType.MVN_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Medical_Claim').getRecordTypeId();
        MVN_Claim__c claim;

        if (oldClaim != NULL) {
            claim = new MVN_Claim__c(
                Id = oldClaim.Id,
                MVN_Copay_Assistance_Program__c = oldClaim.MVN_Copay_Assistance_Program__c
            );
        } else {
            claim = new MVN_Claim__c(RecordTypeId = recordTypeId);
        }

        claim.MVN_Claim_Id__c = stagingClaim.MVN_Claim_Id__c;
        claim.MVN_Claim_Create_Date__c = stagingClaim.MVN_Claim_Created_Date__c;
        claim.MVN_Date_of_Service__c = stagingClaim.MVN_Date_of_Service__c;
        claim.MVN_Payment_Type__c = stagingClaim.MVN_Payment_Type__c;
        claim.MVN_Copay_Before_Benefit_Applied__c = stagingClaim.MVN_Patient_Copay_Before_Benefit__c;
        claim.MVN_Program_Benefit__c = stagingClaim.MVN_Program_Benefit__c;
        claim.MVN_Patient_OOP__c = stagingClaim.MVN_Patient_OOP__c;
        claim.MVN_Check_Number__c = stagingClaim.MVN_Check_Number__c;
        claim.MVN_Trace_Number__c = stagingClaim.MVN_Trace_Number__c;
        claim.MVN_Payment_Date__c = stagingClaim.MVN_Payment_Date__c;
        claim.MVN_Claim_Outcome__c = stagingClaim.MVN_Claim_Outcome__c;
        claim.MVN_Copay_Coinsurance_Amount__c = stagingClaim.MVN_Copay_Amount__c;
        claim.MVN_Claim_Receipt_Date__c = stagingClaim.MVN_Claim_Receipt_Date__c;
        claim.MVN_Claim_Closed_Date__c = stagingClaim.MVN_Claim_Closed_Date__c;
        claim.MVN_Rejected_Reason__c = stagingClaim.MVN_Rejected_Reason__c;
        claim.MVN_EOB_Date__c = stagingClaim.MVN_EOB_Date__c;

        return claim;
    }

    /**
     * Overloaded method that will build a Claim based on Staging Claim.
     * @param stagingClaim
     * @return  `MVN_Claim__c`
     */
    private MVN_Claim__c buildClaim(MVN_Staging_Claim__c stagingClaim) {
        return buildClaim(stagingClaim, null);
    }

    /**
     * Returns a query string for Database.QueryLocator
     * @return  `String`
     */
    private String buildStagingClaimQueryString() {
        Id recordTypeId = Schema.SObjectType.MVN_Staging_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Medical').getRecordTypeId();
        String query = 'SELECT MVN_Check_Number__c,';
              query += '       MVN_Claim_Closed_Date__c,';
              query += '       MVN_Claim_Created_Date__c,';
              query += '       MVN_Claim_Id__c,';
              query += '       MVN_Claim_Outcome__c,';
              query += '       MVN_Claim_Receipt_Date__c,';
              query += '       MVN_Copay_Amount__c,';
              query += '       MVN_Date_of_Service__c,';
              query += '       MVN_EOB_Date__c,';
              query += '       MVN_Error_Message__c,';
              query += '       MVN_Member_Id__c,';
              query += '       MVN_Patient_Copay_Before_Benefit__c,';
              query += '       MVN_Patient_OOP__c,';
              query += '       MVN_Payment_Date__c,';
              query += '       MVN_Payment_Type__c,';
              query += '       MVN_Program_Benefit__c,';
              query += '       MVN_Rejected_Reason__c,';
              query += '       MVN_Status__c,';
              query += '       MVN_Trace_Number__c';
              query += '  FROM MVN_Staging_Claim__c';
              query += ' WHERE RecordTypeId = \'' + recordTypeId + '\'';
              query += '   AND MVN_Status__c IN (\'Pending\', \'Error\')';
        return query;
    }

    private void createActivities(List<MVN_Claim__c> claims) {
        // Create activities when a Copay Medical Claims are approved or rejected.
        List<Case> activitiesToInsert = new List<Case>();
        if (claims.size() > 0) {
            Map<Id, PJN_Assistance_Program__c> assistanceProgramMap = queryAssistanceProgramMap(claims);

            for (MVN_Claim__c claim : claims) {
                if (assistanceProgramMap.containsKey(claim.MVN_Copay_Assistance_Program__c) && claim.MVN_Claim_Outcome__c != null) {
                    PJN_Assistance_Program__c program = assistanceProgramMap.get(claim.MVN_Copay_Assistance_Program__c);
                    Boolean coordinatorEmpty = program.PJN_Care_Plan__r.MVN_Coordinator__c != NULL;

                    activitiesToInsert.add(
                        new Case(
                            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                            AccountId = program.PJN_Account__c,
                            ParentId = program.PJN_Care_Plan__c,
                            HealthCloudGA__DueDate__c = Date.today().addDays(1),
                            Subject = System.Label.MVN_Staging_Claim_Activity_Subject,
                            Description = System.Label.MVN_Staging_Claim_Activity_Description,
                            OwnerId = coordinatorEmpty ? program.PJN_Care_Plan__r.MVN_Coordinator__c : program.PJN_Care_Plan__r.OwnerId
                        )
                    );
                }
            }
        }

        insert activitiesToInsert;
    }

    /**
     * Query the MVN_Claim__c object returning a map with a key of Member ID and Date of Service.
     * @param memberIds
     * @param datesOfService
     * @return  `Map<String, MVN_Claim__c>`
     */
    private Map<String, Map<String,  MVN_Claim__c>> queryClaimMap(Set<String> memberIds, Set<String> datesOfService) {
        
        Map<String, Map<String, MVN_Claim__c>> result = new Map<String, Map<String, MVN_Claim__c>>();
        
        for (MVN_Claim__c claim : [
            SELECT 
                MVN_Care_Plan__c, MVN_Copay_Assistance_Program__c, MVN_Copay_Member_Id__c, 
                MVN_Date_Of_Service_myRare_String__c 
            FROM MVN_Claim__c 
            WHERE 
                MVN_Copay_Member_Id__c IN :memberIds AND 
                MVN_Date_Of_Service_myRare_String__c IN :datesOfService
        ]) {
            if (!result.containsKey(claim.MVN_Copay_Member_Id__c)) {
                result.put(claim.MVN_Copay_Member_Id__c, new Map<String, MVN_Claim__c>());
            }
            if (!result.get(claim.MVN_Copay_Member_Id__c).containsKey(claim.MVN_Date_Of_Service_myRare_String__c)) {
                result.get(claim.MVN_Copay_Member_Id__c).put(claim.MVN_Date_Of_Service_myRare_String__c, claim);
            }
        }

        return result;
    }

    /**
     * Query the PJN_Assistance_Program__c object returning a map with a key of Member ID.
     * @param memberIds
     * @return  `Map<String, PJN_Assistance_Program__c>`
     */
    private Map<String, PJN_Assistance_Program__c> queryAssistanceProgramMap(Set<String> memberIds) {
        Id recordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Copay').getRecordTypeId();
        Map<String, PJN_Assistance_Program__c> result = new Map<String, PJN_Assistance_Program__c>();
        for (PJN_Assistance_Program__c program : [SELECT MVN_Copay_Member_Id__c, PJN_Care_Plan__c FROM PJN_Assistance_Program__c WHERE MVN_Copay_Member_Id__c = :memberIds AND RecordTypeId = :recordTypeId]) {
            result.put(program.MVN_Copay_Member_Id__c, program);
        }
        return result;
    }

    /**
     * Query the PJN_Assistance_Program__c object returning a map with a key of Id
     * @param claims
     * @return  `Map<Id, PJN_Assistance_Program__c>`
     */
    private Map<Id, PJN_Assistance_Program__c> queryAssistanceProgramMap(List<MVN_Claim__c> claims) {
        Set<Id> copayProgramIds = new Set<Id>();
        for (MVN_Claim__c claim : claims) {
            copayProgramIds.add(claim.MVN_Copay_Assistance_Program__c);
        }

        return new Map<Id, PJN_Assistance_Program__c>([SELECT PJN_Account__c, PJN_Care_Plan__c, PJN_Care_Plan__r.MVN_Coordinator__c, PJN_Care_Plan__r.OwnerId FROM PJN_Assistance_Program__c WHERE Id = :copayProgramIds]);
    }
}