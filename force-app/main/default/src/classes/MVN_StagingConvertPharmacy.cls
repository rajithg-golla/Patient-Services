/**
 * @author      Mavens
 * @date        June 30, 2021
 * @description Batch job that converts pharmacy Staging Claims to Claims.
 */
public with sharing class MVN_StagingConvertPharmacy implements Schedulable, Database.Batchable<sObject> {

    /**
     * Schedule execute method which will start batch job
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        Id batchJobId = Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
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
    public void execute(Database.BatchableContext bc, List<sObject> scope) { // NOPMD
        List<MVN_Staging_Claim__c> stagingClaims = (List<MVN_Staging_Claim__c>) scope;
        Set<String> authNumbers = new Set<String>();
        Set<String> memberIds = new Set<String>();

        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            authNumbers.add(stagingClaim.MVN_Claim_Authorization_Number__c);
            memberIds.add(stagingClaim.MVN_Member_Id__c);
        }

        Map<String, MVN_Claim__c> claimMap = queryClaimMap(authNumbers);
        Map<String, PJN_Assistance_Program__c> programMap = queryAssistanceProgramMap(memberIds);

        List<MVN_Claim__c> claimsToUpsert = new List<MVN_Claim__c>();
        List<MVN_Staging_Claim__c> stagingClaimsForUpdate = new List<MVN_Staging_Claim__c>();
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            // Claim match found by Original Claim Auth Number, build claim
            if (String.isNotBlank(stagingClaim.MVN_Claim_Authorization_Number__c) && claimMap.containsKey(stagingClaim.MVN_Claim_Authorization_Number__c)) {
                claimsToUpsert.add(buildClaim(stagingClaim, claimMap.get(stagingClaim.MVN_Claim_Authorization_Number__c)));
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Complete;
                stagingClaim.MVN_Error_Message__c = '';

            // Assistance Progam match found by Member Id, build claim
            } else if (String.isNotBlank(stagingClaim.MVN_Member_Id__c) && programMap.containsKey(stagingClaim.MVN_Member_Id__c)) {
                MVN_Claim__c claim = buildClaim(stagingClaim);
                claim.MVN_Copay_Assistance_Program__c = programMap.get(stagingClaim.MVN_Member_Id__c).Id;
                claim.MVN_Care_Plan__c = programMap.get(stagingClaim.MVN_Member_Id__c).PJN_Care_Plan__c;
                claimsToUpsert.add(claim);
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Complete;
                stagingClaim.MVN_Error_Message__c = '';

            // Original Claim Auth Number and Member Id are blank, match impossible
            } else if (String.isBlank(stagingClaim.MVN_Claim_Authorization_Number__c) && String.isBlank(stagingClaim.MVN_Member_Id__c)) {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Matching_Fields_Blank;

            // Member Id didn't match, Original Claim Auth Number is blank
            } else if (String.isBlank(stagingClaim.MVN_Claim_Authorization_Number__c)) {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Auth_Number_is_Blank;

            // Original Claim Auth Number didn't match, Member Id is blank
            } else if (String.isBlank(stagingClaim.MVN_Member_Id__c)) {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Msg_No_Auth_Match_Member_Id_Blank;

            // Generic no match found error
            } else {
                stagingClaim.MVN_Status__c = System.Label.MVN_Staging_Claim_Conversion_Status_Error;
                stagingClaim.MVN_Error_Message__c = System.Label.MVN_Staging_Claim_Conversion_Error_Copay_Not_Found;
            }
            stagingClaimsForUpdate.add(stagingClaim);
        }

        upsert claimsToUpsert;
        update stagingClaimsForUpdate;
    }


    /**
     * Finish method.
     * @param bc
     */
    public void finish(Database.BatchableContext bc) { //NOPMD
    }

    /**
     * Build a Claim based on Staging Claim and old Claim.
     * @param stagingClaim
     * @param oldClaim
     * @return  `MVN_Claim__c`
     */
    private MVN_Claim__c buildClaim(MVN_Staging_Claim__c stagingClaim, MVN_Claim__c oldClaim) {

        Id recordTypeId = Schema.SObjectType.MVN_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Pharmacy_Claim').getRecordTypeId();
        MVN_Claim__c claim;

        if (oldClaim != NULL) {
            claim = new MVN_Claim__c(Id = oldClaim.Id);
        } else {
            claim = new MVN_Claim__c(RecordTypeId = recordTypeId);
        }

        claim.MVN_Claim_Authorization_Number__c = stagingClaim.MVN_Claim_Authorization_Number__c;
        claim.MVN_Copay_Before_Benefit_Applied__c = stagingClaim.MVN_Patient_Copay_Before_Applied__c;
        claim.MVN_Date_Of_Fill__c = stagingClaim.MVN_Date_Of_Fill__c;
        claim.MVN_Date_Processed__c = stagingClaim.MVN_Date_Processed__c;
        claim.MVN_Date_Written__c = stagingClaim.MVN_Date_Written__c;
        claim.MVN_Days_Supply__c = stagingClaim.MVN_Day_Supply__c;
        claim.MVN_Dispense_As_Written__c = stagingClaim.MVN_DAW__c;
        claim.MVN_Drug_Description__c = stagingClaim.MVN_Drug_Description__c;
        claim.MVN_Group_Number__c = stagingClaim.MVN_Group_Number__c;
        claim.MVN_NDC__c = stagingClaim.MVN_NDC__c;
        claim.MVN_New_Refill_Code__c = stagingClaim.MVN_New_Refill_Code__c;
        claim.MVN_Number_Of_Refills__c = stagingClaim.MVN_Number_Of_Refills__c;
        claim.MVN_Original_Claim_Authorization_Number__c = stagingClaim.MVN_Original_Claim_Authorization_Number__c;
        claim.MVN_Other_Coverage_Code__c = stagingClaim.MVN_Other_Coverage_Code__c;
        claim.MVN_Patient_Benefit__c = stagingClaim.MVN_Patient_Benefit__c;
        claim.MVN_Patient_Gender__c = stagingClaim.MVN_Patient_Gender__c;
        claim.MVN_Patient_OOP__c = stagingClaim.MVN_Patient_OOP__c;
        claim.MVN_Pharmacy_Transaction_Fee__c = stagingClaim.MVN_Pharmacy_Transaction_Fee__c;
        claim.MVN_Quantity__c = stagingClaim.MVN_Quantity__c;
        claim.MVN_Rx_Number__c = stagingClaim.MVN_Rx_Number__c;
        claim.MVN_Submission_Method__c = stagingClaim.MVN_Submission_Method__c;
        claim.MVN_Transaction_Type__c = stagingClaim.MVN_Transaction_Type__c;

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
        Id recordTypeId = Schema.SObjectType.MVN_Staging_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Pharmacy').getRecordTypeId();
        String query = 'SELECT MVN_Claim_Authorization_Number__c,';
              query += '       MVN_Date_Of_Fill__c,';
              query += '       MVN_Date_Processed__c,';
              query += '       MVN_Date_Written__c,';
              query += '       MVN_DAW__c,';
              query += '       MVN_Day_Supply__c,';
              query += '       MVN_Drug_Description__c,';
              query += '       MVN_Group_Number__c,';
              query += '       MVN_Member_Id__c,';
              query += '       MVN_NDC__c,';
              query += '       MVN_New_Refill_Code__c,';
              query += '       MVN_Number_Of_Refills__c,';
              query += '       MVN_Original_Claim_Authorization_Number__c,';
              query += '       MVN_Other_Coverage_Code__c,';
              query += '       MVN_Patient_Benefit__c,';
              query += '       MVN_Patient_Copay_Before_Applied__c,';
              query += '       MVN_Patient_Gender__c,';
              query += '       MVN_Patient_OOP__c,';
              query += '       MVN_Pharmacy_Transaction_Fee__c,';
              query += '       MVN_Quantity__c,';
              query += '       MVN_Rx_Number__c,';
              query += '       MVN_Submission_Method__c,';
              query += '       MVN_Transaction_Type__c';
              query += '  FROM MVN_Staging_Claim__c';
              query += ' WHERE RecordTypeId = \'' + recordTypeId + '\'';
              query += '   AND MVN_Status__c IN (\'Pending\', \'Error\')';
        return query;
    }


    /**
     * Query the MVN_Claim__c object returning a map with a key of Authorization Number.
     * @param authNumbers
     * @return  `Map<String, MVN_Claim__c>`
     */
    private Map<String, MVN_Claim__c> queryClaimMap(Set<String> authNumbers) {
        Map<String, MVN_Claim__c> result = new Map<String, MVN_Claim__c>();
        for (MVN_Claim__c claim : [SELECT MVN_Claim_Authorization_Number__c, MVN_Care_Plan__c FROM MVN_Claim__c WHERE MVN_Claim_Authorization_Number__c IN :authNumbers]){
            result.put(claim.MVN_Claim_Authorization_Number__c, claim);
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
}