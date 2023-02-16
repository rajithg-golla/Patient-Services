/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_ContactInformationCtrl
* @group ContactInformation
*/
@isTest(isParallel=true) private class PJN_ContactInformationCtrlTest {

    static Account patient;
    static Case carePlan;
    static PJN_Contact_Information__c contactInfo1;
    static PJN_Contact_Information__c contactInfo2;
    static DataUsePurpose dataUsePurposeRecord;

    static {
        createDataUsePurpose();
        createContactInfoRecords();
        createCarePlan();
    }

    static void createContactInfoRecords() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient 1 Test'
            }
        );
        PJN_TestFactoryContactInformation contactInformationFactory = new PJN_TestFactoryContactInformation();
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(contactInformationFactory.constructAddress(new Map<String,Object>{
            'RecordTypeId' => SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            'PJN_Address_Line_1__c' => 'Patient1 Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient1 Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Patient1 City',
            'PJN_Postal_Code__c' => '1111',
            'PJN_Country__c' => PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue(),
            'PJN_Account__c' => patient.Id
        }));
        contactInfoList.add(contactInformationFactory.constructAddress(new Map<String,Object>{
            'RecordTypeId' => SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            'PJN_Address_Line_1__c' => 'Patient2 Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient2 Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Patient2 City',
            'PJN_Postal_Code__c' => '2222',
            'PJN_Country__c' => PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue(),
            'PJN_Account__c' => patient.Id
        }));
        insert contactInfoList;
        contactInfo1 = contactInfoList.get(0);
        contactInfo2 = contactInfoList.get(1);

        List<PJN_Channel_Consent__c> channelConsentList = new List<PJN_Channel_Consent__c>();
        channelConsentList.add(new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = contactInfoList.get(0).Id,
            PJN_Effective_From__c = System.today().addDays(-10),
            PJN_Effective_To__c = System.today().addDays(10),
            PJN_Privacy_Consent_Status__c = 'Opt Out',
            PJN_Data_Use_Purpose__c = dataUsePurposeRecord.Id
        ));
        channelConsentList.add(new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = contactInfoList.get(1).Id,
            PJN_Effective_From__c = System.today().addDays(-10),
            PJN_Effective_To__c = System.today().addDays(10),
            PJN_Privacy_Consent_Status__c = 'Opt In',
            PJN_Data_Use_Purpose__c = dataUsePurposeRecord.Id
        ));
        insert channelConsentList;
    }

    static void createCarePlan() {
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        carePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Care Plan Case',
                'PJN_Program_DeveloperName__c' => 'PJN_CLP',
                'AccountId' => patient.Id
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

    @isTest
    private static void testGetContactInformationFromAccount() {
        PJN_DataTable contactInfoResult;
        Test.startTest();
            contactInfoResult = PJN_ContactInformationCtrl.getContactInformation(patient.Id);
        Test.stopTest();
        System.assertEquals(2, contactInfoResult.data.size());
        System.assertEquals(4, contactInfoResult.columns.size());
    }

    @isTest
    private static void testGetContactInformationFromCarePlan() {
        Test.startTest();
            PJN_DataTable contactInfoResult = PJN_ContactInformationCtrl.getContactInformation(carePlan.Id);
        Test.stopTest();
        System.assertEquals(2, contactInfoResult.data.size());
        System.assertEquals(5, contactInfoResult.columns.size());
    }

    @isTest
    private static void testGetContactInformationNoRecord() {
        Test.startTest();
            PJN_DataTable contactInfoResult = PJN_ContactInformationCtrl.getContactInformation(contactInfo1.Id);
        Test.stopTest();
        System.assert(contactInfoResult.data.isEmpty());
    }

    @isTest
    private static void testGetContactInformationException() {
        Test.startTest();
            try {
                PJN_ContactInformationCtrl.getContactInformation(null);
            } catch (AuraHandledException exc) {
                System.assert(exc.getMessage().contains(Label.PJN_Contact_Information_Exception_General_Message.replace('{0}', '')));
            }
        Test.stopTest();
    }


    @isTest
    private static void testOptInExistingContactInformation() {

        Test.startTest();
            PJN_ContactInformationCtrl.optInContactInformation(contactInfo1.Id, 'PJN_CLP');
        Test.stopTest();
        PJN_Channel_Consent__c channelConsent = [
            SELECT
                PJN_Privacy_Consent_Status__c,
                PJN_Effective_From__c,
                PJN_Effective_To__c
            FROM
                PJN_Channel_Consent__c
            WHERE
                PJN_Contact_Information__c = :contactInfo1.Id
        ];
        System.assertEquals('Opt In', channelConsent.PJN_Privacy_Consent_Status__c);
        System.assertEquals(Date.today(), channelConsent.PJN_Effective_From__c);
        System.assertEquals(Date.today().addMonths(12), channelConsent.PJN_Effective_To__c);
    }

    @isTest
    private static void testOptInNewContactInformationNoDataUsePurposeException() {
        Test.startTest();
            try {
                PJN_ContactInformationCtrl.optInContactInformation(contactInfo2.Id, 'PJN_CLP');
            } catch (AuraHandledException exc) {
                String msg = String.format(Label.PJN_Contact_Information_Exception_General_Message,
                                    new List<String>{Label.PJN_Contact_Information_Consent_DataUsePurpose_Exception});
                System.assertEquals(msg, exc.getMessage());
            }
        Test.stopTest();
    }

    @isTest
    private static void testOptInNewContactInformation() {
        Test.startTest();
            PJN_ContactInformationCtrl.optInContactInformation(contactInfo2.Id, 'PJN_CLP');
        Test.stopTest();
        PJN_Channel_Consent__c channelConsent = [
            SELECT
                PJN_Privacy_Consent_Status__c,
                PJN_Effective_From__c,
                PJN_Effective_To__c
            FROM
                PJN_Channel_Consent__c
            WHERE
                PJN_Contact_Information__c = :contactInfo2.Id
        ];
        System.assertEquals('Opt In', channelConsent.PJN_Privacy_Consent_Status__c);
        System.assertEquals(Date.today(), channelConsent.PJN_Effective_From__c);
        System.assertEquals(Date.today().addMonths(12), channelConsent.PJN_Effective_To__c);
    }

    @isTest
    private static void testOptOutExistingContactInformation() {
        Test.startTest();
            PJN_ContactInformationCtrl.optOutContactInformation(contactInfo1.Id, 'PJN_CLP');
        Test.stopTest();
        PJN_Channel_Consent__c channelConsent = [
            SELECT
                PJN_Privacy_Consent_Status__c,
                PJN_Effective_From__c,
                PJN_Effective_To__c
            FROM
                PJN_Channel_Consent__c
            WHERE
                PJN_Contact_Information__c = :contactInfo1.Id
        ];
        System.assertEquals('Opt Out', channelConsent.PJN_Privacy_Consent_Status__c);
        System.assertEquals(null, channelConsent.PJN_Effective_From__c);
        System.assertEquals(null, channelConsent.PJN_Effective_To__c);
    }

    @isTest
    private static void testOptOutNewContactInformationNoDataUsePurposeException() {
        Test.startTest();
            try {
                PJN_ContactInformationCtrl.optOutContactInformation(contactInfo2.Id, 'PJN_CLP');
            } catch (AuraHandledException exc) {
                String msg = String.format(Label.PJN_Contact_Information_Exception_General_Message,
                                    new List<String>{Label.PJN_Contact_Information_Consent_DataUsePurpose_Exception});
                System.assertEquals(msg, exc.getMessage());
            }
        Test.stopTest();
    }

    @isTest
    private static void testGetParentTypeAccount() {
        Test.startTest();
            System.assertEquals('Account', PJN_ContactInformationCtrl.getParentType(patient.Id));
        Test.stopTest();
    }

    @isTest
    private static void testGetParentTypeCarePlan() {
        Test.startTest();
            System.assertEquals('CarePlan', PJN_ContactInformationCtrl.getParentType(carePlan.Id));
        Test.stopTest();
    }

    @isTest
    private static void testGetParentTypeException() {
        Test.startTest();
            try {
                PJN_ContactInformationCtrl.getParentType(null);
            } catch (AuraHandledException exc) {
                System.assert(exc.getMessage().contains(Label.PJN_Contact_Information_Exception_General_Message.replace('{0}', '')));
            }
        Test.stopTest();
    }

    @isTest
    private static void testDeleteContactInformation() {
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId(),
            LastName = 'Patient 1 Test'
        );
        insert patient;

        PJN_Contact_Information__c contactInformation = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Address_Line_1__c = 'Patient2 Address Line 1',
            PJN_Address_Line_2__c = 'Patient2 Address Line 2',
            PJN_Set_as_Primary__c = true,
            PJN_City__c = 'Patient2 City',
            PJN_Postal_Code__c = '2222',
            PJN_Country__c = PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue(),
            PJN_Account__c = patient.Id
        );
        insert contactInformation;

        Test.startTest();
            PJN_ContactInformationCtrl.deleteContactInformation(contactInformation.Id);
        Test.stopTest();

        System.assert(([SELECT Id FROM PJN_Contact_Information__c WHERE Id = :contactInformation.Id]).isEmpty());
    }

    @isTest
    private static void testDeleteException() {
        Test.startTest();
            try {
                PJN_ContactInformationCtrl.deleteContactInformation(null);
            } catch (AuraHandledException exc) {
                System.assert(exc.getMessage().contains(Label.PJN_Contact_Information_Exception_General_Message.replace('{0}', '')));
            }
        Test.stopTest();
    }
}