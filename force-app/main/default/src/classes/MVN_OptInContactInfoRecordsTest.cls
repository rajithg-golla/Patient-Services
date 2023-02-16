/**
* @author Mavens
* @description Test class for MVN_OptInContactInfoRecords
* @group ContactInformation
*/
@isTest
private class MVN_OptInContactInfoRecordsTest {

    @testSetup static void setup() {
        createDataUsePurpose();
        createContactInfoRecords();
    }

    @isTest static void testDoNotCreateChannelConsentsForNoCarePlan() {
        Account patient = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            insert new Case(
                RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Request').getRecordTypeId(),
                Subject = 'Care Plan Case',
                PJN_Program_DeveloperName__c = 'PJN_CLP',
                AccountId = patient.Id
            );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT count() FROM PJN_Channel_Consent__c],
            'Channel Consents found for RTs diffrent to CarePlan'
        );
    }

    // @isTest static void testCreateChannelConsents() {
    //     Account patient = [SELECT Id FROM Account LIMIT 1];
    //     Test.startTest();
    //         insert new Case(
    //             RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
    //             Subject = 'Care Plan Case',
    //             PJN_Program_DeveloperName__c = 'PJN_CLP',
    //             AccountId = patient.Id
    //         );
    //     Test.stopTest();

    //     System.assertEquals(
    //         2,
    //         [SELECT count() FROM PJN_Channel_Consent__c],
    //         'Channel Consents not found for CarePlan'
    //     );
    // }

    static void createDataUsePurpose() {
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
    }

    static void createContactInfoRecords() {
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Patient 1 Test'

        );
        insert patient;
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(
            new PJN_Contact_Information__c(
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
                PJN_Address_Line_1__c = 'Patient1 Address Line 1',
                PJN_Address_Line_2__c = 'Patient1 Address Line 2',
                PJN_Set_as_Primary__c = true,
                PJN_City__c = 'Patient1 City',
                PJN_Postal_Code__c = '1111',
                PJN_Country__c = PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue(),
                PJN_Account__c = patient.Id

            )
        );
        contactInfoList.add(
            new PJN_Contact_Information__c(
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
                PJN_Email__c = 'Patient1@emailtest.com',
                PJN_Set_as_Primary__c = true,
                PJN_Account__c = patient.Id

            )
        );
        insert contactInfoList;
    }
}