/**
 * @author      Mavens
 * @date        10/2020
 * @description Controller for the Get PAP Eligibility Quick Action
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_EvaluatePAPEligibilityCtrl {

    @TestVisible
    private static PJN_AssistProgEligibilityConfigQuery apeConfig = new PJN_AssistProgEligibilityConfigQuery();
    /**
     *
     * @param apeRecordId
     * @returns `Map<String, Object>` A map with two keys:
     *      1. apeRecord is the payload record
     *      2. sourceMap is a map of field names to the source that populated them
     * @exception throws an Aura Exception on error
     */
    @AuraEnabled
    public static Map<String, Object> getPayloadRecord(String apeRecordId) {
        // TODO: ability to accept additional fields or fields to exclude
        String RECORD = Label.PJN_Eval_PAP_Source_Record;
        String PHONE_LOOKUP = Label.PJN_Eval_PAP_Source_Phone_Lookup;
        String ADDRESS_LOOKUP = Label.PJN_Eval_PAP_Source_Address_Lookup;
        String ACCOUNT_INFO = Label.PJN_Eval_PAP_Source_Account_Record;
        String ACCOUNT_PRIMARY_PHONE = Label.PJN_Eval_PAP_Source_Account_Primary_Phone;
        String ACCOUNT_PRIMARY_ADDR = Label.PJN_Eval_PAP_Source_Account_Primary_Addr;

        Map<String, String> sourceMap = new Map<String, String>{
            'PJN_First_Name__c' => RECORD,
            'PJN_Middle_Name__c' => RECORD,
            'PJN_Last_Name__c' => RECORD,
            'PJN_Phone__c' => RECORD,
            'PJN_Social_Security_Number__c' => RECORD,
            'PJN_Date_of_Birth__c' => RECORD,
            'PJN_Address__c' => RECORD,
            'PJN_City__c' => RECORD,
            'PJN_State__c' => RECORD,
            'PJN_Zip__c' => RECORD
        };
        PJN_Assistance_Program__c apeRecord;

        try {
            apeRecord = queryApeRecord(apeRecordId);

            // If phone is blank pull it from the phone lookup if provided
            if (apeRecord.PJN_Phone_Lookup__c != null && String.isBlank(apeRecord.PJN_Phone__c)) {
                apeRecord.PJN_Phone__c = apeRecord.PJN_Phone_Lookup__r.PJN_Phone__c;
                sourceMap.put('PJN_Phone__c', PHONE_LOOKUP);
            }
            // If address is blank pull it from the address lookup if provided
            if (addressNotPopulated(apeRecord) && apeRecord.PJN_Address_Lookup__c != null) {
                PJN_Contact_Information__c address = apeRecord.PJN_Address_Lookup__r;
                populateAddress(apeRecord, address, sourceMap, ADDRESS_LOOKUP);
            }

            // Run checks to populate fields with account data
            if (apeRecord.PJN_Care_Plan__c != null && apeRecord.PJN_Care_Plan__r.AccountId != null) {
                Account acct = apeRecord.PJN_Care_Plan__r.Account;

                // If name is blank pull from account
                if (String.isBlank(apeRecord.PJN_First_Name__c)
                    && String.isBlank(apeRecord.PJN_Middle_Name__c)
                    && String.isBlank(apeRecord.PJN_Last_Name__c)
                ) {
                    apeRecord.PJN_First_Name__c = acct.FirstName;
                    sourceMap.put('PJN_First_Name__c', ACCOUNT_INFO);

                    apeRecord.PJN_Middle_Name__c = acct.MiddleName;
                    sourceMap.put('PJN_Middle_Name__c', ACCOUNT_INFO);

                    apeRecord.PJN_Last_Name__c = acct.LastName;
                    sourceMap.put('PJN_Last_Name__c', ACCOUNT_INFO);
                }

                // set dob if not populated
                if (apeRecord.PJN_Date_of_Birth__c == null) {
                    apeRecord.PJN_Date_of_Birth__c = acct.MVN_Birthdate__c;
                    sourceMap.put('PJN_Date_of_Birth__c', ACCOUNT_INFO);
                }

                // if address still not populated, look to account primary address
                if (addressNotPopulated(apeRecord) && acct.PJN_Primary_Address__c != null) {
                    PJN_Contact_Information__c address = acct.PJN_Primary_Address__r;
                    populateAddress(apeRecord, address, sourceMap, ACCOUNT_PRIMARY_ADDR);
                }

                // if phone still not populated, look to account primary phone
                if (String.isBlank(apeRecord.PJN_Phone__c) && acct.PJN_Primary_Phone__c != null) {
                    PJN_Contact_Information__c phone = acct.PJN_Primary_Phone__r;
                    apeRecord.PJN_Phone__c = phone.PJN_Phone__c;
                    sourceMap.put('PJN_Phone__c', ACCOUNT_PRIMARY_PHONE);
                }
            }

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        return new Map<String, Object>{
            // return record without all the lookups populated
            'apeRecord' => new PJN_Assistance_Program__c(
                Id = apeRecord.Id,
                PJN_First_Name__c = apeRecord.PJN_First_Name__c,
                PJN_Middle_Name__c = apeRecord.PJN_Middle_Name__c,
                PJN_Last_Name__c = apeRecord.PJN_Last_Name__c,
                PJN_Phone__c = apeRecord.PJN_Phone__c,
                PJN_Social_Security_Number__c = apeRecord.PJN_Social_Security_Number__c,
                PJN_Date_of_Birth__c = apeRecord.PJN_Date_of_Birth__c,
                PJN_Address__c = apeRecord.PJN_Address__c,
                PJN_City__c = apeRecord.PJN_City__c,
                PJN_State__c = apeRecord.PJN_State__c,
                PJN_Zip__c = apeRecord.PJN_Zip__c
            ),
            'sourceMap' => sourceMap,
            'labelMap' => getLabelMap()
        };
    }

    /**
     * Facilite rendering of the summary by providing a label map in the repsonse
     * @returns `Map<String, String>`
     */
    @TestVisible
    private static Map<String, String> getLabelMap() {
        Map<String, Schema.SObjectField> dfr = PJN_Assistance_Program__c.sObjectType
            .getDescribe()
            .fields.getMap();

        return new Map<String, String> {
            'PJN_First_Name__c' => dfr.get('PJN_First_Name__c').getDescribe().getLabel(),
            'PJN_Middle_Name__c' => dfr.get('PJN_Middle_Name__c').getDescribe().getLabel(),
            'PJN_Last_Name__c' => dfr.get('PJN_Last_Name__c').getDescribe().getLabel(),
            'PJN_Phone__c' => dfr.get('PJN_Phone__c').getDescribe().getLabel(),
            'PJN_Social_Security_Number__c' => dfr.get('PJN_Social_Security_Number__c').getDescribe().getLabel(),
            'PJN_Date_of_Birth__c' => dfr.get('PJN_Date_of_Birth__c').getDescribe().getLabel(),
            'PJN_Address__c' => dfr.get('PJN_Address__c').getDescribe().getLabel(),
            'PJN_City__c' => dfr.get('PJN_City__c').getDescribe().getLabel(),
            'PJN_State__c' => dfr.get('PJN_State__c').getDescribe().getLabel(),
            'PJN_Zip__c' => dfr.get('PJN_Zip__c').getDescribe().getLabel()
        };
    }

    /**
     * Query for a pap record, by id, with related care plan account data and phone/address lookup data
     * @param apeRecordId
     * @returns `PJN_Assistance_Program__c`
     */
    private static PJN_Assistance_Program__c queryApeRecord(Id apeRecordId) {
        return [
            SELECT
                Id,
                PJN_First_Name__c,
                PJN_Middle_Name__c,
                PJN_Last_Name__c,
                PJN_Phone__c,
                PJN_Social_Security_Number__c,
                PJN_Date_of_Birth__c,
                PJN_Address__c,
                PJN_City__c,
                PJN_State__c,
                PJN_Zip__c,
                PJN_Care_Plan__c,
                PJN_Care_Plan__r.AccountId,
                PJN_Care_Plan__r.Account.FirstName,
                PJN_Care_Plan__r.Account.MiddleName,
                PJN_Care_Plan__r.Account.LastName,
                PJN_Care_Plan__r.Account.PJN_Primary_Phone__r.PJN_Phone__c,
                PJN_Care_Plan__r.Account.PJN_Primary_Address__r.PJN_Address_Line_1__c,
                PJN_Care_Plan__r.Account.PJN_Primary_Address__r.PJN_Address_Line_2__c,
                PJN_Care_Plan__r.Account.PJN_Primary_Address__r.PJN_City__c,
                PJN_Care_Plan__r.Account.PJN_Primary_Address__r.PJN_State__c,
                PJN_Care_Plan__r.Account.PJN_Primary_Address__r.PJN_Postal_Code__c,
                PJN_Care_Plan__r.Account.MVN_Birthdate__c,
                PJN_Phone_Lookup__c,
                PJN_Phone_Lookup__r.PJN_Phone__c,
                PJN_Address_Lookup__c,
                PJN_Address_Lookup__r.PJN_Address_Line_1__c,
                PJN_Address_Lookup__r.PJN_Address_Line_2__c,
                PJN_Address_Lookup__r.PJN_City__c,
                PJN_Address_Lookup__r.PJN_State__c,
                PJN_Address_Lookup__r.PJN_Postal_Code__c
            FROM
                PJN_Assistance_Program__c
            WHERE
                Id = :apeRecordId
        ];
    }

    /**
     * @param apeRecord - the record to check for a poulated address
     * @returns `Boolean` - indicates if the address is not populated
     */
    private static Boolean addressNotPopulated(PJN_Assistance_Program__c apeRecord) {
        return String.isBlank(apeRecord.PJN_Address__c) &&
            String.isBlank(apeRecord.PJN_City__c)  &&
            String.isBlank(apeRecord.PJN_State__c) &&
            String.isBlank(apeRecord.PJN_Zip__c);
    }

    /**
     * Given an Assistance Program Eligibiility record, and address, the source map, and a source,
     * map the address values from the address record to the apeRecord and update the source map to
     * indicate where the values came from
     * @param apeRecord - PJN_Assistance_Program__c
     * @param address - PJN_Contact_Information__c
     * @param sourceMap - Map<String, String>
     * @param source -String
     */
    private static void populateAddress(
        PJN_Assistance_Program__c apeRecord,
        PJN_Contact_Information__c address,
        Map<String, String> sourceMap,
        String source
    ) {
        apeRecord.PJN_Address__c = address.PJN_Address_Line_1__c;
        if (String.isNotBlank(address.PJN_Address_Line_2__c)) {
            apeRecord.PJN_Address__c += ' ' + address.PJN_Address_Line_2__c;
        }
        sourceMap.put('PJN_Address__c', source);

        apeRecord.PJN_City__c = address.PJN_City__c;
        sourceMap.put('PJN_City__c', source);

        apeRecord.PJN_State__c = address.PJN_State__c;
        sourceMap.put('PJN_State__c', source);

        apeRecord.PJN_Zip__c = address.PJN_Postal_Code__c;
        sourceMap.put('PJN_Zip__c', source);
    }

    /**
     * Using the passed Assistance Program Eligibility record, call the configured Financial Clearing
     * House to determine the household size, household income, and federal poverty level of the
     * patient. Record those values on the pap record and set the updated eligiblity status from the
     * record to the response.
     * @param apeRecord
     * @returns `PJN_PAPEligibilityResponse`
     * @exception
     */
    @AuraEnabled
    public static PJN_PAPEligibilityResponse getPapEligibility(PJN_Assistance_Program__c apeRecord){
        try {
            PJN_Assistance_Prog_Eligibility_Config__mdt config = apeConfig.getConfigurationByDevName('PJN_Main_Configuration');
            Type clearingHouseType = Type.forName(config.PJN_Clearing_House_Class__c);
            PJN_FinancialClearingHouseIntf clearingHouse = (PJN_FinancialClearingHouseIntf) clearingHouseType.newInstance();
            PJN_PAPEligibilityRequest request = new PJN_PAPEligibilityRequest(apeRecord);
            PJN_PAPEligibilityResponse response = clearingHouse.getEligibility(request);

            if (!response.hasErrors) {
                PJN_Assistance_Program__c apWithPovLevel  =  [
                    SELECT
                        PJN_Care_Plan__r.PJN_Program__r.PJN_PAP_Federal_Poverty_Level_Threshold__c
                    FROM
                        PJN_Assistance_Program__c
                    WHERE
                        Id = :apeRecord.Id
                ];

                apeRecord.PJN_Federal_Poverty_Level_Percentage__c = response.federalPovertyLevelPercent;
                apeRecord.PJN_Estimated_Household_Income__c = response.estimatedHouseholdIncome;
                apeRecord.PJN_Estimated_Household_Size__c = response.estimatedHouseholdSize;

                // set the program federal poverty level as it is set now
                Decimal programThreshold = 100;
                if (apWithPovLevel.PJN_Care_Plan__r != null && apWithPovLevel.PJN_Care_Plan__r.PJN_Program__r != null
                    && apWithPovLevel.PJN_Care_Plan__r.PJN_Program__r.PJN_PAP_Federal_Poverty_Level_Threshold__c != null
                ) {
                    programThreshold = apWithPovLevel.PJN_Care_Plan__r.PJN_Program__r.PJN_PAP_Federal_Poverty_Level_Threshold__c;
                }
                apeRecord.PJN_Program_Federal_Poverty_Threshold__c = programThreshold;

                // flip the record type
                apeRecord.RecordTypeId = SObjectType.PJN_Assistance_Program__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('PJN_Patient_Assistance_Program_Locked')
                    .getRecordTypeId();

                update apeRecord;

                apeRecord = [
                    SELECT PJN_PAP_Eligibility__c
                    FROM PJN_Assistance_Program__c
                    WHERE Id = :apeRecord.Id
                ];
                response.setOutcome(apeRecord.PJN_PAP_Eligibility__c);
            }

            return response;

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}