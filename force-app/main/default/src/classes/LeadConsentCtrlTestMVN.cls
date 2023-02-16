@isTest
public class LeadConsentCtrlTestMVN {
    
    @TestSetup
    static void makeData(){
        AdobeSignAPITestMVN.createAdobeSignTemplate();

        insert new Regeneron_Adobe_Sign_Settings_MVN__c(
            Authentication_Endpoint_MVN__c  = 'https://auth.endpoint.adobe.com',
            Client_Id_MVN__c = 'A-client-id',
            Client_Secret_MVN__c = 'A-client-secret',
            Refresh_Token_MVN__c = 'A-refresh-token',
            REST_API_Endpoint_MVN__c = 'https://rest.endpoint.adobe.com',
            Webhook_Public_Site_MVN__c = 'https://public-site-regeneron.salesforce.com'
        );
    }

    @isTest
    private static void itShouldCreateAndSendAnAgreement() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Lead consumer = new Lead(
            FirstName = 'Dean',
            LastName = 'Martin',
            Email= 'dean.martin@test.dedsi.com',
            HealthCloudGA__BirthDate__c = Date.today().addDays(-365 * 50),
            Gender_MVN__c  = 'Male'
        );

        insert consumer;

        Test.startTest();
        String agreementId = LeadConsentCtrlMVN.createAndSendAgreement(consumer.Id, 'DEDSI Consent', false);
        Test.stopTest();

        System.assertEquals('1234567890Id', agreementId);
        System.assertEquals(1, [
            SELECT COUNT()
            FROM echosign_dev1__SIGN_Agreement__c
        ]);
    }

    @isTest
    private static void itShouldGetSigningUrl() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Test.startTest();
        String signingUrl = LeadConsentCtrlMVN.getSigningUrl('agreementId');
        Test.stopTest();

        System.assertEquals('https://signingurl.adobesign.com', signingUrl);
    }

    @isTest
    private static void itShouldGetAgreementDocId() {
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c (
            echosign_dev1__Document_Key__c = 'documentKey'
        );
        insert agreement;

        Test.startTest();
        String docKey = LeadConsentCtrlMVN.getAgreementDocId(agreement.Id);
        Test.stopTest();

        System.assertEquals('documentKey', docKey);
    }   
}