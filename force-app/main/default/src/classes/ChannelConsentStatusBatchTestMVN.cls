/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description Unit tests for ChannelConsentStatusBatchMVN
 */
@isTest
@SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation')
private class ChannelConsentStatusBatchTestMVN {

    public static final String CHANNEL_CONSENT_OPT_IN = 'Opt In';
    public static final String CHANNEL_CONSENT_OPT_OUT = 'Opt Out';
    public static final String CONTACT_INFO_EMAIL_RECORD_TYPE = 'PJN_Email';
    public static final String MARKETING_CLOUD_ACTIVE = 'Active';
    public static final String MARKETING_CLOUD_UNSUBSCRIBED = 'Unsubscribed';

    private static List<Account> patients;
    private static Map<Id,PJN_Contact_Information__c> patientEmails;
    private static List<PJN_Channel_Consent__c> emailConsents;

    @isTest
    static void itShouldUpdateMarketingCloudOnNewChannelConsents() {
        givenPatientEmails();
        whenChannelConsentsCreated();
        thenMarketingCloudIsUpdated();
        System.assert(true, 'Ran unsuccessfully.');
    }

    @isTest
    static void itShouldHandleException() {
        givenPatientEmails();
        try {
            whenExceptionIsThrown();
        } catch (Exception ex) {
            System.assert(false, 'Exception caught: ' + ex.getMessage());
        }
    }

    static void givenPatientEmails() {
        patients = new List<Account>();
        for (Integer i = 0; i < ChannelConsentStatusChangeMVN.BATCH_THRESHHOLD; i++) {
            patients.add(
                new Account(
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Libtayo_Marketing_Program_Participant_MVN').getRecordTypeId(),
                    LastName = 'Test' + String.valueOf(i)
                )
            );
        }
        insert patients;

        List<Id> patientIds = new List<Id>();
        for (Account patient : patients) {
            patientIds.add(patient.Id);
        }
        patients = [
            SELECT PersonContactId,
                   PJN_Primary_Email__c
              FROM Account
             WHERE Id IN :patientIds
        ];

        patientEmails = new Map<Id,PJN_Contact_Information__c>();
        for (Integer i = 0; i < ChannelConsentStatusChangeMVN.BATCH_THRESHHOLD; i++) {
            patientEmails.put(
                patients[i].PersonContactId,
                new PJN_Contact_Information__c(
                    RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
                    PJN_Account__c = patients[i].Id
                )
            );
        }
        insert patientEmails.values();

        for (Account patient : patients) {
            patient.PJN_Primary_Email__c = patientEmails.get(patient.PersonContactId).Id;
        }
        update patients;
    }

    static void whenChannelConsentsCreated() {
        emailConsents = new List<PJN_Channel_Consent__c>();
        for (Id patientId : patientEmails.keySet()) {
            emailConsents.add(
                new PJN_Channel_Consent__c(
                    PJN_Contact_Information__c = patientEmails.get(patientId).Id,
                    PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN,
                    Pending_Consent_Status_Batch_MVN__c = true
                )
            );
        }

        Test.setMock(HttpCalloutMock.class, new MarketingCloudAPIResponseMockMVN((List<String>) new List<Id>(patientEmails.keySet())));
        insert emailConsents;

        for(PJN_Channel_Consent__c emailConsent : emailConsents) {
            emailConsent.PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN;
            emailConsent.Pending_Consent_Status_Batch_MVN__c = true;
        }

        update emailConsents;
        Test.startTest();

        ChannelConsentStatusBatchMVN channelConsentStatusBatch = new ChannelConsentStatusBatchMVN();
        Database.executeBatch(channelConsentStatusBatch);

        Test.stopTest();
    }

    static void whenExceptionIsThrown() {
        emailConsents = new List<PJN_Channel_Consent__c>();
        for (Id patientId : patientEmails.keySet()) {
            emailConsents.add(
                new PJN_Channel_Consent__c(
                    PJN_Contact_Information__c = patientEmails.get(patientId).Id,
                    PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN,
                    Pending_Consent_Status_Batch_MVN__c = true
                )
            );
        }

        // Pass in Account Id as subscriber key instead of PersonContactId
        List<Id> patientIds = new List<Id>();
        for (Account patient : patients) {
            patientIds.add(patient.Id);
        }

        MarketingCloudAPIResponseMockMVN theMock = new MarketingCloudAPIResponseMockMVN(patientIds);

        Test.setMock(HttpCalloutMock.class, theMock);
        insert emailConsents;

        for(PJN_Channel_Consent__c emailConsent : emailConsents) {
            emailConsent.PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN;
            emailConsent.Pending_Consent_Status_Batch_MVN__c = true;
        }

        update emailConsents;
        theMock.throwException = true;
        Test.startTest();

        ChannelConsentStatusBatchMVN channelConsentStatusBatch = new ChannelConsentStatusBatchMVN();
        channelConsentStatusBatch.execute(null);

        Test.stopTest();
    }

    static void thenMarketingCloudIsUpdated() {
        List<Id> emailConsentIds = new List<Id>();
        for (PJN_Channel_Consent__c emailConsent : emailConsents) {
            emailConsentIds.add(emailConsent.Id);
        }

        emailConsents = [
            SELECT Latest_Marketing_Cloud_API_Status_MVN__c,
                   Pending_Consent_Status_Batch_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :emailConsentIds
        ];

        for (PJN_Channel_Consent__c emailConsent : emailConsents) {
            System.assert(String.isNotBlank(emailConsent.Latest_Marketing_Cloud_API_Status_MVN__c), 'Latest_Marketing_Cloud_API_Status_MVN__c is blank.');
            System.assertEquals(false, emailConsent.Pending_Consent_Status_Batch_MVN__c, 'Pending_Consent_Status_Batch_MVN__c marked true.');
        }
    }

    @isTest
    static void itShouldSetChannelConsentStatusPendingIfUpdatedInFuture() {
        givenPatientEmails();
        whenChannelConsentsAreUpdatedInFuture();
        thenPendingConsentStatusBatchTrue();
        System.assert(true, 'Ran unsuccessfully.');
    }

    static void whenChannelConsentsAreUpdatedInFuture() {
        emailConsents = new List<PJN_Channel_Consent__c>();
        for (Id patientId : patientEmails.keySet()) {
            emailConsents.add(
                new PJN_Channel_Consent__c(
                    PJN_Contact_Information__c = patientEmails.get(patientId).Id,
                    PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN,
                    Pending_Consent_Status_Batch_MVN__c = false
                )
            );
        }

        Test.setMock(HttpCalloutMock.class, new MarketingCloudAPIResponseMockMVN(new List<Id>(patientEmails.keySet())));
        insert emailConsents;

        List<Id> channelConsentIds = new List<Id>();

        for(PJN_Channel_Consent__c emailConsent : emailConsents) {
            channelConsentIds.add(emailConsent.Id);
        }

        Test.startTest();

        updateChannelConsentsInFuture(channelConsentIds);

        Test.stopTest();
    }

    @future static void updateChannelConsentsInFuture(List<Id> channelConsentIds) {
        List<PJN_Channel_Consent__c> channelConsents = [
            SELECT PJN_Privacy_Consent_Status__c,
                   Latest_Marketing_Cloud_API_Status_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :channelConsentIds
        ];

        List<PJN_Channel_Consent__c> channelConsentsToUpdate = new List<PJN_Channel_Consent__c>();

        for(PJN_Channel_Consent__c channelConsent : channelConsents) {
            channelConsentsToUpdate.add(new PJN_Channel_Consent__c(
                Id = channelConsent.Id,
                PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_OUT,
                Latest_Marketing_Cloud_API_Status_MVN__c = ''
            ));
        }

        update channelConsentsToUpdate;
    }

    static void thenPendingConsentStatusBatchTrue(){
        List<Id> emailConsentIds = new List<Id>();
        for (PJN_Channel_Consent__c emailConsent : emailConsents) {
            emailConsentIds.add(emailConsent.Id);
        }
        emailConsents = [
            SELECT Pending_Consent_Status_Batch_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :emailConsentIds
        ];
        for (PJN_Channel_Consent__c emailConsent : emailConsents) {
            System.assertEquals(true, emailConsent.Pending_Consent_Status_Batch_MVN__c, 'Pending_Consent_Status_Batch_MVN__c is false, should be true.');
        }
    }



    @future static void insertChannelConsentsInFuture(List<Id> channelConsentIds) {
        List<PJN_Channel_Consent__c> channelConsents = [
            SELECT PJN_Privacy_Consent_Status__c,
                   Latest_Marketing_Cloud_API_Status_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :channelConsentIds
        ];

        List<PJN_Channel_Consent__c> channelConsentsToUpdate = new List<PJN_Channel_Consent__c>();

        for(PJN_Channel_Consent__c channelConsent : channelConsents) {
            channelConsentsToUpdate.add(new PJN_Channel_Consent__c(
                Id = channelConsent.Id,
                PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_OUT,
                Latest_Marketing_Cloud_API_Status_MVN__c = ''
            ));
        }

        update channelConsentsToUpdate;
    }
}