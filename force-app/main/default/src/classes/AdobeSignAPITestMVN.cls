@isTest
public class AdobeSignAPITestMVN {
    
    @TestSetup
    static void makeData(){
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
    private static void itShouldGetAnAccessToken() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Test.startTest();
        System.assertEquals('1234567890Access', AdobeSignAPIMVN.getAccessToken());
        Test.stopTest();
    }

    @isTest
    private static void itShouldSendAgreementForSigning() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        AdobeSignAgreementMVN agreement = new AdobeSignAgreementMVN('name', 'sigType', 'state', 'externalId');

        Test.startTest();
        System.assertEquals('1234567890Id', AdobeSignAPIMVN.sendForSigning(agreement));
        Test.stopTest();
    }

    @isTest
    private static void itShouldCreateWebhook() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Test.startTest();
        AdobeSignAPIMVN.createWebhook();
        System.assert(true); // just exercising he code, assertions made in the mock callout
        Test.stopTest();
    }

    @isTest
    private static void itShouldHandleWebHookVerification() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/api/adobe/';
        req.httpMethod = 'GET';
        req.headers.put(
            'X-AdobeSign-ClientId',
            Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().Client_Id_MVN__c
        );

        Test.startTest();
        RestContext.request = req;
        RestContext.response = res;
        AdobeSignAPIMVN.handleInitialization();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(
            Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().Client_Id_MVN__c, 
            RestContext.response.headers.get('X-AdobeSign-ClientId')
        );
    }

    @isTest
    private static void itShouldHandleWebHookRejection() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/api/adobe/';
        req.httpMethod = 'GET';
        req.headers.put('X-AdobeSign-ClientId', 'A Bad Client Id');

        Test.startTest();
        RestContext.request = req;
        RestContext.response = res;
        AdobeSignAPIMVN.handleInitialization();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode);
    }

    @isTest
    private static void itShouldHandleWebHookNotification() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        echosign_dev1__Agreement_Template__c template = createAdobeSignTemplate();
        Lead consumer  = new Lead(
            FirstName = 'Dean',
            LastName = 'Martin',
            Email = 'dean.martin@dedsi.com'
        );
        insert consumer;

        echosign_dev1__SIGN_Agreement__c agreementObject =  new echosign_dev1__SIGN_Agreement__c(
            Name = template.echosign_dev1__Name__c,
            echosign_dev1__Recipient_Lead__c = consumer.Id,
            echosign_dev1__Process_Template__c = template.echosign_dev1__Data_Mapping__c,
            echosign_dev1__Merge_Mapping__c = template.echosign_dev1__Merge_Mapping__c,
            echosign_dev1__Agreement_Type__c = template.echosign_dev1__Agreement_Type__c,
            CustomConsumer__c = consumer.Id,
            echosign_dev1__Document_Key__c = 'AgreementIdFromAdobe',
            echosign_dev1__Post_Sign_Redirect_URL__c = template.echosign_dev1__Post_Sign_Redirect_URL__c,
            echosign_dev1__Post_Sign_Redirect_Delay__c = template.echosign_dev1__Post_Sign_Redirect_Delay__c,
            echosign_dev1__Recipient_Addresses__c = consumer.Email,
            echosign_dev1__SignatureOrder__c = 'Recipient signs, then I sign',
            echosign_dev1__SignatureType__c = 'e-Signature',
            echosign_dev1__Status__c = 'Out for Signature',
            echosign_dev1__Enable_Hosted_Signing__c = true
        );
        insert agreementObject;

        RestContext.request = new RestRequest();
        RestContext.request.headers.put(
            'X-AdobeSign-ClientId', 
            Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().Client_Id_MVN__c
        );

        AdobeSignAPIMVN.WebhookNotification webhook = new AdobeSignAPIMVN.WebhookNotification();
        AdobeSignAPIMVN.Agreement agreement = new AdobeSignAPIMVN.Agreement();
        agreement.Id = 'AgreementIdFromAdobe';
        agreement.Name = 'Test Agreement';
        agreement.status = 'SIGNED';
        webhook.agreement = agreement;

        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(webhook));
        RestContext.response = new RestResponse();

        Test.startTest();
        AdobeSignAPIMVN.handleWebhookEvent();
        Test.stopTest();

        List<Lead> leads = [SELECT FirstName FROM Lead]; 
        System.assertEquals(1, leads.size());
        System.assertEquals('DeanUpdated', leads[0].FirstName); // mock updates first name
        System.assertEquals(1, [SELECT COUNT() FROM Attachment WHERE Name = 'Test Agreement' and ParentId = :agreementObject.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM echosign_dev1__SIGN_Agreement__c WHERE Id = :agreementObject.Id AND echosign_dev1__Status__c = 'Signed']);
    }

    @isTest
    private static void itShouldGetSigningUrls() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Test.startTest();
        AdobeSignAPIMVN.SigningUrlResponse signingUrls = AdobeSignAPIMVN.getSigningUrl('AdobeSignAgreementId');
        Test.stopTest();

        System.assertEquals(1, signingUrls.signingUrlSetInfos.size());
        System.assertEquals(1, signingUrls.signingUrlSetInfos[0].signingUrls.size());
        System.assertEquals('https://signingurl.adobesign.com', signingUrls.signingUrlSetInfos[0].signingUrls[0].esignUrl);
    }


    /******************* HELPER METHODS *******************/
    public static echosign_dev1__Agreement_Template__c createAdobeSignTemplate() {
        echosign_dev1__Agreement_Template__c template = new echosign_dev1__Agreement_Template__c(
            Name = 'DEDSI Consent',
            echosign_dev1__Name__c = 'Regeneron Consent & Release Form',
            echosign_dev1__Post_Sign_Redirect_URL__c = 'https://www.looktoyourfuture.com/',
            echosign_dev1__Post_Sign_Redirect_Delay__c = 3,
            echosign_dev1__Merge_Mapping__c = buildMergeMapping().Id,
            echosign_dev1__Data_Mapping__c = buildDataMapping().Id
        );
        insert template;
        return template;
    }

    private static echosign_dev1__SIGN_Merge_Mapping__c buildMergeMapping() {
        echosign_dev1__SIGN_Merge_Mapping__c mergeMapping = new echosign_dev1__SIGN_Merge_Mapping__c(
            Name = 'DEDSI Program Merge Mapping'
        );

        insert mergeMapping;

        List<echosign_dev1__SIGN_Form_Field_Mapping__c> formFieldMappings = new List<echosign_dev1__SIGN_Form_Field_Mapping__c>{
            new echosign_dev1__SIGN_Form_Field_Mapping__c(
                echosign_dev1__Data_Mapping__c = mergeMapping.Id,
                echosign_dev1__Form_Field_Name__c = '"First Name"',
                echosign_dev1__Index__c = 1               
            ),
            new echosign_dev1__SIGN_Form_Field_Mapping__c(
                echosign_dev1__Data_Mapping__c = mergeMapping.Id,                
                echosign_dev1__Form_Field_Name__c = '"Last Name"', 
                echosign_dev1__Index__c = 2               
            )
        };
        insert formFieldMappings;

        List<echosign_dev1__SIGN_Form_Field_Mapping_Entry__c> formFieldMappingEntries = new List<echosign_dev1__SIGN_Form_Field_Mapping_Entry__c> {
            new echosign_dev1__SIGN_Form_Field_Mapping_Entry__c(
                echosign_dev1__Form_Field_Mapping__c = formFieldMappings[0].Id,
                echosign_dev1__Type__c = 'Salesforce Object Field',
                echosign_dev1__Field_Reference_Name__c = 'FirstName',
                echosign_dev1__Object_Reference_Path__c = 'echosign_dev1__Recipient_Lead__r',
                echosign_dev1__Index__c = 1
            ),
            new echosign_dev1__SIGN_Form_Field_Mapping_Entry__c(
                echosign_dev1__Form_Field_Mapping__c = formFieldMappings[1].Id,
                echosign_dev1__Type__c = 'Salesforce Object Field',
                echosign_dev1__Field_Reference_Name__c = 'LastName',
                echosign_dev1__Object_Reference_Path__c = 'echosign_dev1__Recipient_Lead__r',
                echosign_dev1__Index__c = 2
            )
        };
        insert formFieldMappingEntries;

        return mergeMapping;
    }

    private static echosign_dev1__SIGN_Data_Mapping__c buildDataMapping() {
        echosign_dev1__SIGN_Data_Mapping__c dataMapping = new echosign_dev1__SIGN_Data_Mapping__c(
            Name = 'DEDSI Program Consent Mapping'
        );
        insert dataMapping;

        echosign_dev1__SIGN_Object_Mapping__c objectMapping = new echosign_dev1__SIGN_Object_Mapping__c(
            echosign_dev1__Field_API_Name__c = 'CustomConsumer__c',
            echosign_dev1__Fully_Qualified_API__c = 'CustomConsumer__r',
            echosign_dev1__SIGN_Data_Mapping__c = dataMapping.Id,
            Name = 'Lead'
        );
        insert objectMapping;

        List<echosign_dev1__SIGN_Field_Mapping__c> fieldMappings = new List<echosign_dev1__SIGN_Field_Mapping__c> {
            new echosign_dev1__SIGN_Field_Mapping__c(
                Name = 'FirstName',
                echosign_dev1__SIGN_Object_Mapping__c = objectMapping.Id,
                echosign_dev1__Source__c = '"first"',
                echosign_dev1__Type__c = 'EchoSign Form Field',
                echosign_dev1__Index__c = 1
            ),
            new echosign_dev1__SIGN_Field_Mapping__c(
                Name = 'LastName',
                echosign_dev1__SIGN_Object_Mapping__c = objectMapping.Id,
                echosign_dev1__Source__c = '"last"',
                echosign_dev1__Type__c = 'EchoSign Form Field',
                echosign_dev1__Index__c = 2
            )
        };
        insert fieldMappings;

        return dataMapping;
    }
}