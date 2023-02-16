/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_ContactInformationCtrl
* @group ContactInformation
*/
@isTest(isParallel=true) private class PJN_ConsentHdlrTest {

    static Account patient;
    static DataUsePurpose dataUsePurposeRecord;

    static {
        createPatient();
        createDataUsePurpose();
    }

    static void createPatient() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId(),
                'LastName' => 'Patient 1 Test'
            }
        );
    }

    static void createDataUsePurpose() {
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;

        dataUsePurposeRecord = new DataUsePurpose(
            Name = 'Test',
            PJN_Type__c = 'Program Consent',
            PJN_Effective_Months__c = 12,
            PurposeId = program.Id,
            PJN_External_Id__c = 'PJN_CLP_ProgramConsent'
        );
        insert dataUsePurposeRecord;
    }

    @isTest private static void testCreateChannelConsentException() {
        CareProgram differentProgram = new CareProgram(
            Name = 'Different Test Program',
            PJN_Program_DeveloperName__c = 'Different_PJN_CLP',
            StartDate = Date.today()
        );
        insert differentProgram;

        dataUsePurposeRecord.PurposeId = differentProgram.Id;
        update dataUsePurposeRecord;

        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id
        );
        insert contactInfo;

        Test.startTest();
            try {
                PJN_ConsentHdlr.processConsentForContactInformation(new List<Id>{contactInfo.Id}, 'PJN_CLP', 'Opt In');
            } catch (PJN_ConsentException exc) {
                System.assert(exc != null);
                System.assertEquals(Label.PJN_Contact_Information_Consent_DataUsePurpose_Exception, exc.getMessage());
            }
        Test.stopTest();


    }

    @isTest private static void testCreateOptInChannelConsent() {
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id
        );
        insert contactInfo;

        Test.startTest();
            PJN_ConsentHdlr.processConsentForContactInformation(new List<Id>{contactInfo.Id}, 'PJN_CLP', 'Opt In');
        Test.stopTest();

        PJN_Channel_Consent__c channelConsent = [SELECT
                                                    PJN_Data_Use_Purpose__c,
                                                    PJN_Contact_Type__c,
                                                    PJN_Effective_From__c,
                                                    PJN_Effective_To__c,
                                                    PJN_Privacy_Consent_Status__c
                                                FROM
                                                    PJN_Channel_Consent__c
                                                WHERE
                                                    PJN_Contact_Information__c = :contactInfo.Id];
        System.assertEquals(dataUsePurposeRecord.Id, channelConsent.PJN_Data_Use_Purpose__c);
        System.assertEquals('Phone', channelConsent.PJN_Contact_Type__c);
        System.assertEquals(System.today(), channelConsent.PJN_Effective_From__c);
        System.assertEquals(System.today().addMonths(12), channelConsent.PJN_Effective_To__c);
        System.assertEquals('Opt In', channelConsent.PJN_Privacy_Consent_Status__c);
    }

    // @isTest private static void testUpdateOptOutChannelConsent() {
    //     PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
    //         RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
    //         PJN_Email__c = 'hola@test.com',
    //         PJN_Account__c = patient.Id
    //     );
    //     insert contactInfo;

    //     PJN_Channel_Consent__c channelConsent = new PJN_Channel_Consent__c(
    //         PJN_Data_Use_Purpose__c = dataUsePurposeRecord.Id,
    //         PJN_Contact_Type__c = 'Email',
    //         PJN_Effective_From__c = System.today(),
    //         PJN_Effective_To__c = System.today().addMonths(12),
    //         PJN_Privacy_Consent_Status__c = 'Opt In',
    //         PJN_Contact_Information__c = contactInfo.Id
    //     );
    //     insert channelConsent;

    //     Test.startTest();
    //         PJN_ConsentHdlr.processConsentForContactInformation(new List<Id>{contactInfo.Id}, 'PJN_CLP', 'Opt Out');
    //     Test.stopTest();

    //     channelConsent = [SELECT
    //                         PJN_Data_Use_Purpose__c,
    //                         PJN_Contact_Type__c,
    //                         PJN_Effective_From__c,
    //                         PJN_Effective_To__c,
    //                         PJN_Privacy_Consent_Status__c
    //                     FROM
    //                         PJN_Channel_Consent__c
    //                     WHERE
    //                         PJN_Contact_Information__c = :contactInfo.Id];
    //     System.assertEquals(dataUsePurposeRecord.Id, channelConsent.PJN_Data_Use_Purpose__c);
    //     System.assertEquals('Email', channelConsent.PJN_Contact_Type__c);
    //     System.assertEquals(null, channelConsent.PJN_Effective_From__c);
    //     System.assertEquals(null, channelConsent.PJN_Effective_To__c);
    //     System.assertEquals('Opt Out', channelConsent.PJN_Privacy_Consent_Status__c);
    // }

}