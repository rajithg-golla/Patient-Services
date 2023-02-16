/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description Unit tests for MarketingCloudSubscriberUpdateMVN
 */
@isTest
private class MarketingCloudSubscriberUpdateTestMVN {

    public static final String CHANNEL_CONSENT_OPT_IN = 'Opt In';
    public static final String CHANNEL_CONSENT_OPT_OUT = 'Opt Out';
    public static final String CONTACT_INFO_EMAIL_RECORD_TYPE = 'PJN_Email';
    public static final String MARKETING_CLOUD_ACTIVE = 'Active';
    public static final String MARKETING_CLOUD_UNSUBSCRIBED = 'Unsubscribed';

    private static Account patient;
    private static PJN_Contact_Information__c patientEmail;
    private static PJN_Channel_Consent__c emailConsent;

    @isTest
    static void itShouldUpdateMarketingCloudOnNewChannelConsent() {
        givenPatientEmail();
        whenChannelConsentCreated();
        thenMarketingCloudIsUpdated();
    }

    @isTest 
    static void itShouldUpdateMarketingCloudOnChangedChannelConsent() {
        givenPatientEmail();
        whenChannelConsentUpdated();
        thenMarketingCloudIsUpdated();
    }

    static void givenPatientEmail() {
        patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Libtayo_Marketing_Program_Participant_MVN').getRecordTypeId(),
            LastName = 'Test'
        );
        insert patient;
        
        patientEmail = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
            PJN_Account__c = patient.Id
        );
        insert patientEmail;

        patient = [
            SELECT PersonContactId,
                   PJN_Primary_Email__c
              FROM Account 
             WHERE Id = :patient.Id
        ];
        patient.PJN_Primary_Email__c = patientEmail.Id;
        update patient;
    }

    static void whenChannelConsentCreated() {
        emailConsent = new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = patientEmail.Id,
            PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN
        );

        Test.setMock(HttpCalloutMock.class, new MarketingCloudAPIResponseMockMVN(new List<String> { patient.PersonContactId }));
        Test.startTest();
        insert emailConsent;
        Test.stopTest();
    }

    static void whenChannelConsentUpdated() {
        emailConsent = new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = patientEmail.Id,
            PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_IN
        );

        Test.setMock(HttpCalloutMock.class, new MarketingCloudAPIResponseMockMVN(new List<String> { patient.PersonContactId }));
        Test.startTest();
        insert emailConsent;
        emailConsent.PJN_Privacy_Consent_Status__c = CHANNEL_CONSENT_OPT_OUT;
        update emailConsent;
        Test.stopTest();
    }

    static void thenMarketingCloudIsUpdated() {
        emailConsent = [
            SELECT Latest_Marketing_Cloud_API_Status_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id = :emailConsent.Id
        ];
        System.assert(String.isNotBlank(emailConsent.Latest_Marketing_Cloud_API_Status_MVN__c));
    }
}