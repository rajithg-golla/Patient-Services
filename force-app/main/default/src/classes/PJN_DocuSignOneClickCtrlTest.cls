/**
 * @author Mavens
 * @date May 2019
 * @description Unit tests for PJN_DocuSignOneClickCtrl
 * @group DocuSign One Click
 */
@isTest(isParallel=true) private class PJN_DocuSignOneClickCtrlTest {
    static Case testCarePlan;

    static {
        CareProgram cholecap = new CareProgram(
            Name = 'Cholecap',
            StartDate = Date.today(),
            PJN_Program_DeveloperName__c = 'Cholecap'
        );
        insert cholecap;

        testCarePlan = new Case(
            PJN_Program__c = cholecap.Id, // to match the program
            Subject = 'Test Subject', // to match the additional filter
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
        );

        insert testCarePlan;
    }

    @isTest private static void itShouldReturnMatchingMetadata() {
        PJN_DocuSignOneClickCtrl.metadataProvider = (PJN_DocuSignOneClickMetadata) Test.createStub(PJN_DocuSignOneClickMetadata.class, new PJN_DocuSignOneClickMock());

        insert new PJN_DocuSign_Template__c(
            Name = 'Test Template',
            PJN_Template_Name__c = 'Test Template',
            PJN_Template_Id__c = '0000-1111-abcd-9999'
        );

        Test.startTest();
        String paramsString = PJN_DocuSignOneClickCtrl.generateEnvelopeParams(testCarePlan.Id);
        Test.stopTest();
        System.debug(paramsString);
        System.assertEquals(
            'SourceID='+testCarePlan.Id+'&RC=&RSL=&RSRO=&RROS=0&CCRM=&CCTM=&CCNM=&CRCL=&CRL=Email~HardCodedEmail;FirstName~HardCodedFirstName;LastName~Test+Subject;Role~;SignInPersonName~;RoutingOrder~;AccessCode~;SMSAuthPhone~;RecipientNote~;SignNow~,LoadDefaultContacts~0&OCO=&DST=0000-1111-abcd-9999&LA=1&LF=0&CEM=Test Email Body&CES=Test Email Subject&STB=&SSB=&SES=&SEM=&SRS=&SCS=&RES=',
            paramsString
        );
    }

    @isTest private static void itShouldThrowErrorWhenTemplateIsNotFound() {
        PJN_DocuSignOneClickCtrl.metadataProvider = (PJN_DocuSignOneClickMetadata) Test.createStub(PJN_DocuSignOneClickMetadata.class, new PJN_DocuSignOneClickMock());

        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            String paramsString = PJN_DocuSignOneClickCtrl.generateEnvelopeParams(testCarePlan.Id);
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
            String expectedErrorString = String.format(
                Label.PJN_D1C_Unable_to_Find_Template,
                new List<String>{ 'Test Template' }
            );
            System.assertEquals(expectedErrorString, ex.getMessage());
        }
        Test.stopTest();

        System.assert(exceptionCaught);
    }

    @isTest private static void itShouldThrowErrorWhenRecordNotFound() {
        PJN_DocuSignOneClickCtrl.metadataProvider = (PJN_DocuSignOneClickMetadata) Test.createStub(PJN_DocuSignOneClickMetadata.class, new PJN_DocuSignOneClickMock());

        delete testCarePlan;
        Boolean exceptionCaught = false;
        Test.startTest();
            try {
                exceptionCaught = true;
                String paramsString = PJN_DocuSignOneClickCtrl.generateEnvelopeParams(testCarePlan.Id);
            } catch (AuraHandledException ex) {
                System.assertEquals(Label.PJN_D1C_Unable_to_query_record, ex.getMessage());
            }
        Test.stopTest();

        System.assert(exceptionCaught);
    }

    @isTest private static void itShouldThrowErrorWhenSettingFound() {
        PJN_DocuSignOneClickCtrl.metadataProvider = (PJN_DocuSignOneClickMetadata) Test.createStub(PJN_DocuSignOneClickMetadata.class, new PJN_DocuSignOneClickMock(true));

        Boolean exceptionCaught = false;
        Test.startTest();
            try {
                exceptionCaught = true;
                String paramsString = PJN_DocuSignOneClickCtrl.generateEnvelopeParams(testCarePlan.Id);
            } catch (AuraHandledException ex) {
                System.assertEquals(Label.PJN_D1C_Unable_to_Locate_Setting, ex.getMessage());
            }
        Test.stopTest();

        System.assert(exceptionCaught);
    }

    @isTest private static void PJN_itShouldRunDocuSignOneClickMetadataQueries() {
        PJN_DocuSignOneClickMetadata metadataProvider = new PJN_DocuSignOneClickMetadata();
        Boolean allRan = false;
        // given we don't know will exist in a given org we can only exercise these queries
        try {
            metadataProvider.getSettingsForObject(Account.getSObjectType());
            metadataProvider.getRecipients('dummySettingId');
            metadataProvider.getRecipientFields('00000000dummyid');
            allRan = true;
        } catch (exception ex) {

        }
        System.assert(allRan);
    }
}