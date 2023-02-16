/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_EvaluatePAPEligibilityCtrl
 * @group       AssistanceProgramEligibilty
 */
@isTest
public with sharing class PJN_EvaluatePAPEligibilityCtrlTest {

    @TestSetup
    static void makeData() {
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;

        insert new DataUsePurpose(
            Name = 'Test',
            PJN_Type__c = 'Program Consent',
            PJN_Effective_Months__c = 12,
            PurposeId = program.Id,
            PJN_External_Id__c = 'PJN_CLP_ProgramConsent'
        );

        Account patient = new Account(
            FirstName = 'Dean',
            MiddleName = 'Paul',
            LastName = 'Martin',
            MVN_Birthdate__c = Date.newInstance(1917, 6, 7),
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        insert patient;

        List<PJN_Contact_Information__c> phonesAndAddresses = new List<PJN_Contact_Information__c> {
            new PJN_Contact_Information__c(
                PJN_Account__c = patient.Id,
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
                PJN_Phone__c = '(555) 111-2222',
                PJN_Set_As_Primary__c = true
            ),
            new PJN_Contact_Information__c(
                PJN_Account__c = patient.Id,
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
                PJN_Address_Line_1__c = '511 North Maple St.',
                PJN_Address_Line_2__c = 'Suite 1',
                PJN_City__c = 'Beverly Hills',
                PJN_State__c = 'CA',
                PJN_Postal_Code__c = '90210',
                PJN_Set_As_Primary__c = true
            ),
            new PJN_Contact_Information__c(
                PJN_Account__c = patient.Id,
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
                PJN_Phone__c = '(555) 888-9999',
                PJN_Set_As_Primary__c = false
            ),
            new PJN_Contact_Information__c(
                PJN_Account__c = patient.Id,
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
                PJN_Address_Line_1__c = '115 North Maple St.',
                PJN_Address_Line_2__c = 'Suite 2',
                PJN_City__c = 'Mary Valleys',
                PJN_State__c = 'FL',
                PJN_Postal_Code__c = '90209',
                PJN_Set_As_Primary__c = false
            )
        };
        insert phonesAndAddresses;

        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Program__c = program.Id,
            PJN_Program_DeveloperName__c = program.PJN_Program_DeveloperName__c
        );
        insert carePlan;
    }

    @isTest
    private static void itShouldGetPayloadInformationFromRecord() {
        Case carePlan = [SELECT Id FROM Case LIMIT 1];

        PJN_Assistance_Program__c apeRecord = new PJN_Assistance_Program__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_First_Name__c = 'Francis',
            PJN_Middle_Name__c = 'Albert',
            PJN_Last_Name__c = 'Sinatra',
            PJN_Date_of_Birth__c = Date.newInstance(1915, 12, 12),
            PJN_Social_Security_Number__c = '000-00-0000',
            PJN_Phone__c = '555-666-7777',
            PJN_Address__c = '415 Monroe St.',
            PJN_City__c = 'Hoboken',
            PJN_State__c = 'NJ',
            PJN_Zip__c = '07030'
        );

        insert apeRecord;

        Test.startTest();
        Map<String, Object> payload = PJN_EvaluatePAPEligibilityCtrl.getPayloadRecord(apeRecord.Id);
        Test.stopTest();

        PJN_Assistance_Program__c payloadApeRecord = (PJN_Assistance_Program__c) payload.get('apeRecord');
        System.assertEquals('Francis', payloadApeRecord.PJN_First_Name__c);
        System.assertEquals('Albert', payloadApeRecord.PJN_Middle_Name__c);
        System.assertEquals('Sinatra', payloadApeRecord.PJN_Last_Name__c);
        System.assertEquals(Date.newInstance(1915, 12, 12), payloadApeRecord.PJN_Date_of_Birth__c);
        System.assertEquals('555-666-7777', payloadApeRecord.PJN_Phone__c);
        System.assertEquals('000-00-0000', payloadApeRecord.PJN_Social_Security_Number__c);
        System.assertEquals('415 Monroe St.', payloadApeRecord.PJN_Address__c);
        System.assertEquals('Hoboken', payloadApeRecord.PJN_City__c);
        System.assertEquals('NJ', payloadApeRecord.PJN_State__c);
        System.assertEquals('07030', payloadApeRecord.PJN_Zip__c);

        Map<String, String> sourceMap = (Map<String, String>) payload.get('sourceMap');
        System.assert(!sourceMap.isEmpty());
        for (String key : sourceMap.keySet()) {
            System.assertEquals(Label.PJN_Eval_PAP_Source_Record, sourceMap.get(key));
        }
    }

    @isTest
    private static void itShouldGetPayloadInformationFromAccountAndPrimaries() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId() LIMIT 1];

        PJN_Assistance_Program__c apeRecord = new PJN_Assistance_Program__c(
            PJN_Care_Plan__c = carePlan.Id
        );

        insert apeRecord;

        Test.startTest();
        Map<String, Object> payload = PJN_EvaluatePAPEligibilityCtrl.getPayloadRecord(apeRecord.Id);
        Test.stopTest();

        PJN_Assistance_Program__c payloadApeRecord = (PJN_Assistance_Program__c) payload.get('apeRecord');
        System.assertEquals('Dean', payloadApeRecord.PJN_First_Name__c);
        System.assertEquals('Paul', payloadApeRecord.PJN_Middle_Name__c);
        System.assertEquals('Martin', payloadApeRecord.PJN_Last_Name__c);
        System.assertEquals(Date.newInstance(1917, 6, 7), payloadApeRecord.PJN_Date_of_Birth__c);
        System.assertEquals('511 North Maple St. Suite 1', payloadApeRecord.PJN_Address__c);
        System.assertEquals('Beverly Hills', payloadApeRecord.PJN_City__c);
        System.assertEquals('CA', payloadApeRecord.PJN_State__c);
        System.assertEquals('90210', payloadApeRecord.PJN_Zip__c);

        Map<String, String> sourceMap = (Map<String, String>) payload.get('sourceMap');
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_First_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Middle_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Last_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Primary_Phone, sourceMap.get('PJN_Phone__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Record, sourceMap.get('PJN_Social_Security_Number__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Date_of_Birth__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Primary_Addr, sourceMap.get('PJN_Address__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Primary_Addr, sourceMap.get('PJN_City__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Primary_Addr, sourceMap.get('PJN_State__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Primary_Addr, sourceMap.get('PJN_Zip__c'));
    }

    @isTest
    private static void itShouldGetPayloadInformationFromAccountAndLookups() {
        Case carePlan = [SELECT Id, AccountId FROM Case WHERE RecordTypeId = :SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId() LIMIT 1];
        PJN_Contact_Information__c phone;
        PJN_Contact_Information__c address;

        for (PJN_Contact_Information__c ci: [SELECT Id, PJN_Phone__c, PJN_Address_Line_1__c, RecordType.DeveloperName FROM PJN_Contact_Information__c WHERE PJN_Account__c = :carePlan.AccountId]) {
            if (ci.PJN_Phone__c =='(555) 888-9999' && ci.RecordType.DeveloperName == 'PJN_Phone') {
                phone = ci;
            }
            if (ci.PJN_Address_Line_1__c == '115 North Maple St.' && ci.RecordType.DeveloperName == 'PJN_Address') {
                address = ci;
            }
        }
        PJN_Assistance_Program__c apeRecord = new PJN_Assistance_Program__c(
            PJN_Account__c = carePlan.AccountId,
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Address_Lookup__c = address.Id,
            PJN_Phone_Lookup__c = phone.Id
        );
        insert apeRecord;

        Test.startTest();
        Map<String, Object> payload = PJN_EvaluatePAPEligibilityCtrl.getPayloadRecord(apeRecord.Id);
        Test.stopTest();

        PJN_Assistance_Program__c payloadApeRecord = (PJN_Assistance_Program__c) payload.get('apeRecord');
        System.assertEquals('Dean', payloadApeRecord.PJN_First_Name__c);
        System.assertEquals('Paul', payloadApeRecord.PJN_Middle_Name__c);
        System.assertEquals('Martin', payloadApeRecord.PJN_Last_Name__c);
        System.assertEquals(Date.newInstance(1917, 6, 7), payloadApeRecord.PJN_Date_of_Birth__c);
        System.assertEquals('115 North Maple St. Suite 2', payloadApeRecord.PJN_Address__c);
        System.assertEquals('Mary Valleys', payloadApeRecord.PJN_City__c);
        System.assertEquals('FL', payloadApeRecord.PJN_State__c);
        System.assertEquals('90209', payloadApeRecord.PJN_Zip__c);

        Map<String, String> sourceMap = (Map<String, String>) payload.get('sourceMap');
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_First_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Middle_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Last_Name__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Phone_Lookup, sourceMap.get('PJN_Phone__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Record, sourceMap.get('PJN_Social_Security_Number__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Account_Record, sourceMap.get('PJN_Date_of_Birth__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Address_Lookup, sourceMap.get('PJN_Address__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Address_Lookup, sourceMap.get('PJN_City__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Address_Lookup, sourceMap.get('PJN_State__c'));
        System.assertEquals(Label.PJN_Eval_PAP_Source_Address_Lookup, sourceMap.get('PJN_Zip__c'));
    }

    @isTest
    private static void itShouldGenerateALabelMap() {

        Test.startTest();
        Map<String, String> labelMap = PJN_EvaluatePAPEligibilityCtrl.getLabelMap();
        Test.stopTest();

        Map<String, Schema.SObjectField> dfr = PJN_Assistance_Program__c.sObjectType
            .getDescribe()
            .fields.getMap();

        System.assertEquals(dfr.get('PJN_First_Name__c').getDescribe().getLabel(), labelMap.get('PJN_First_Name__c'));
        System.assertEquals(dfr.get('PJN_Middle_Name__c').getDescribe().getLabel(), labelMap.get('PJN_Middle_Name__c'));
        System.assertEquals(dfr.get('PJN_Last_Name__c').getDescribe().getLabel(), labelMap.get('PJN_Last_Name__c'));
        System.assertEquals(dfr.get('PJN_Phone__c').getDescribe().getLabel(), labelMap.get('PJN_Phone__c'));
        System.assertEquals(dfr.get('PJN_Social_Security_Number__c').getDescribe().getLabel(), labelMap.get('PJN_Social_Security_Number__c'));
        System.assertEquals(dfr.get('PJN_Date_of_Birth__c').getDescribe().getLabel(), labelMap.get('PJN_Date_of_Birth__c'));
        System.assertEquals(dfr.get('PJN_Address__c').getDescribe().getLabel(), labelMap.get('PJN_Address__c'));
        System.assertEquals(dfr.get('PJN_City__c').getDescribe().getLabel(), labelMap.get('PJN_City__c'));
        System.assertEquals(dfr.get('PJN_State__c').getDescribe().getLabel(), labelMap.get('PJN_State__c'));
        System.assertEquals(dfr.get('PJN_Zip__c').getDescribe().getLabel(), labelMap.get('PJN_Zip__c'));
    }

    @isTest
    private static void itShouldHandleErrors() {
        AuraHandledException except;
        Test.startTest();
        try {
            Map<String, Object> payload = PJN_EvaluatePAPEligibilityCtrl.getPayloadRecord(null);
        }  catch (AuraHandledException ex) {
            except = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, except);
        System.assertEquals('Script-thrown exception', except.getMessage());
    }

    @isTest
    private static void itShouldGetPapEligibility() {
        // Stub out the metadata query
        PJN_EvaluatePAPEligibilityCtrl.apeConfig = (PJN_AssistProgEligibilityConfigQuery) Test.createStub(
            PJN_AssistProgEligibilityConfigQuery.class,
             new PJN_AssistProgEligibilityConfigQueryMock()
        );

        Case carePlan = [SELECT Id FROM Case LIMIT 1];

        PJN_Assistance_Program__c apeRecord = new PJN_Assistance_Program__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_First_Name__c = 'Francis',
            PJN_Middle_Name__c = 'Albert',
            PJN_Last_Name__c = 'Sinatra',
            PJN_Date_of_Birth__c = Date.newInstance(1915, 12, 12),
            PJN_Social_Security_Number__c = '000-00-0000',
            PJN_Phone__c = '555-666-7777',
            PJN_Address__c = '415 Monroe St.',
            PJN_City__c = 'Hoboken',
            PJN_State__c = 'NJ',
            PJN_Zip__c = '07030'
        );

        insert apeRecord;

        // mock the experian response
        Test.setMock(HttpCalloutMock.class, new PJN_ExperianHealthAPIMock.Search());
        Test.startTest();
        PJN_PAPEligibilityResponse response = PJN_EvaluatePAPEligibilityCtrl.getPapEligibility(apeRecord);
        Test.stopTest();

        System.assertEquals(20000, response.estimatedHouseholdIncome);
        System.assertEquals(4, response.estimatedHouseholdSize);
        System.assertEquals(76.33, response.federalPovertyLevelPercent);
        System.assert(response.errors.isEmpty());
    }

    @isTest
    private static void itShouldHandleGetPapEligibilityException() {
        AuraHandledException except;
        // Case carePlan = [SELECT Id FROM Case LIMIT 1];

        // PJN_Assistance_Program__c apeRecord = new PJN_Assistance_Program__c(
        //     PJN_Care_Plan__c = carePlan.Id
        // );

        // insert apeRecord;
        Test.startTest();
        try {
            PJN_EvaluatePAPEligibilityCtrl.getPapEligibility(null);
        } catch (AuraHandledException ex) {
            except = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, except);
        System.assertEquals('Script-thrown exception', except.getMessage());
    }
}