/**
 * @author      Mavens
 * @group       AdobeSign
 * @description Wrapper for the AdobeSignAPI
 *     - Handles initialization of webhooks
 *     - Handles webhook events for lead consent
 *     - Handles creation of agreements
 *     - Handles obtaining acess token
 */
@RestResource(urlMapping='/api/adobesign')
global without sharing class AdobeSignAPIMVN {

    public class AdobeSignAPIMVNException extends Exception{}

    private static Regeneron_Adobe_Sign_Settings_MVN__c adobeSignSettings {
        get {
            if (adobeSignSettings == null) {
                adobeSignSettings = Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults();
            }
            return adobeSignSettings;
        }
        set;
    }

    /**
     * Send an agreement to Adobe Sign for signature
     * @param AdobeSignAgreementMVN agreement
     * return String: agreement Id     
     */
    public static String sendForSigning(AdobeSignAgreementMVN agreement) {
        
        HttpRequest signingReq = new HttpRequest();
        signingReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'agreements');
        signingReq.setMethod('POST');
        signingReq.setHeader('Authorization', 'Bearer ' + getAccessToken());
        signingReq.setHeader('Content-Type', 'application/json');
        signingReq.setBody( JSON.serialize(agreement) );
       
        HttpResponse response = new Http().send(signingReq);
        if (response.getStatusCode() != 201) {
            throw new AdobeSignAPIMVNException(response.getStatus() + '\n\n' + response.getBody()); 
        }

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (String) responseBody.get('id');
    }

     /**
     * Get an access token from Adobe Sign to allow use of the API
     * return String: access token
     */
    public static string getAccessToken() {
        
        HttpRequest tokenRequest = new HttpRequest();
        tokenRequest.setEndPoint(adobeSignSettings.Authentication_Endpoint_MVN__c + 'oauth/refresh');
        tokenRequest.setMethod('POST');
        tokenRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String payload = 'grant_type=refresh_token' +
            + '&client_id=' + EncodingUtil.urlEncode(adobeSignSettings.Client_Id_MVN__c,'UTF-8') 
            + '&client_secret=' + EncodingUtil.urlEncode(adobeSignSettings.Client_Secret_MVN__c,'UTF-8') 
            + '&refresh_token=' + EncodingUtil.urlEncode(adobeSignSettings.Refresh_Token_MVN__c,'UTF-8'); 

        tokenRequest.setBody(payload);
        HttpResponse response = new Http().send(tokenRequest); 

        if (response.getStatusCode() != 200) {
            throw new AdobeSignAPIMVNException(response.getStatus() + '\n\n' + response.getBody()); 
        }

        // access token returned in JSON as a parameter. Deserialize and pull it out.
        Map<String, Object> responseBody = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        String accessToken = (String) responseBody.get('access_token');
        return accessToken;
    }

    /**
     * Generate a webhook in Adobe to get upates for agreements when they are signed.
     * Invoke via execute anonymous `AdobeSignAPIMVN.createWebhook();`
     */
    public static void createWebhook() {
        HttpRequest webhookReq = new HttpRequest();
        webhookReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'webhooks'); 
        webhookReq.setMethod('POST');
        webhookReq.setHeader('Authorization', 'Bearer ' + getAccessToken());
        webhookReq.setHeader('Content-Type', 'application/json');

        WebHook hook = new WebHook();
        hook.name = 'Notify Salesforce of Agreement Updates';
        hook.scope = 'USER';
        hook.state = 'ACTIVE';
        hook.webhookSubscriptionEvents = new List<String>{ 'AGREEMENT_ACTION_COMPLETED' };
        hook.webhookUrlInfo = new WebhookUrlInfo(adobeSignSettings.Webhook_Public_Site_MVN__c);
        hook.webhookConditionalParams = new WebhookConditionalParams();
        hook.webhookConditionalParams.webhookAgreementEvents.includeDetailedInfo = true;
        hook.webhookConditionalParams.webhookAgreementEvents.includeDocumentsInfo = false;
        hook.webhookConditionalParams.webhookAgreementEvents.includeParticipantsInfo = false;
        hook.webhookConditionalParams.webhookAgreementEvents.includeSignedDocuments = true;
        webhookReq.setBody( JSON.serialize(hook) );

        HttpResponse response = new Http().send(webhookReq);
        
        if (response.getStatusCode() != 201) {
            throw new AdobeSignAPIMVNException(response.getStatus() + '\n\n' + response.getBody());
        }
    }

    /**
     * Handle the initialization of a webhook. When creating a new webhook Adobe sends a get to the defined endpoint
     * and expects back a response with the X-AdobeSign-ClientId and a status code of 200; If the client id doesn't
     * match the configurd client id then a 401 should be returned.
     * @param AdobeSignAgreementMVN agreement
     * return String: agreement Id
     */
    @HttpGet
    global static void handleInitialization() {
        String clientid = RestContext.request.headers.get('X-AdobeSign-ClientId');
        if (clientid == adobeSignSettings.Client_Id_MVN__c) {
            RestContext.response.statusCode = 200;
            RestContext.response.headers.put('X-AdobeSign-ClientId', clientid);
        } else {
            RestContext.response.statusCode = 401;
        }
    }

    /**
     * handle the webhook event sent from adobe. Update the agreement status and map the data back to the parent lead
     */
    @HttpPost
    global static void handleWebhookEvent() {
        // start with an OK response
        RestContext.response.statusCode = 200;

        // validate the client id against the configured Id
        String clientid = RestContext.request.headers.get('X-AdobeSign-ClientId');
        RestContext.response.headers.put('X-AdobeSign-ClientId', clientid);
        
        if (clientid != adobeSignSettings.Client_Id_MVN__c) {
            // if they id's don't match simply respond with an OK so the webhook stops trying, but don't process anything
            return;
        }

        WebhookNotification notification = (WebhookNotification) JSON.deserialize(
            RestContext.request.requestBody.toString(), 
            WebhookNotification.class
        );

        if (notification.agreement.status != 'SIGNED') {
            // currently only dealing with "Signed" events
            return;
        }
        
        // locate the agreement object for the given agreement id
        echosign_dev1__SIGN_Agreement__c agreement;
        
        List<echosign_dev1__SIGN_Agreement__c> agreements = [
            SELECT echosign_dev1__Status__c,
                   echosign_dev1__Process_Template__c,
                   CustomConsumer__c
              FROM echosign_dev1__SIGN_Agreement__c
             WHERE echosign_dev1__Document_Key__c = :notification.agreement.id
               AND echosign_dev1__Status__c != 'Signed'
        ];

        if (!agreements.isEmpty()) {
            agreement = agreements[0];
        } 

        if (agreement == null) {
            // If the agreement is not found respond with an OK to stop the webhook from sending again
            return;
        }

        // going to be making a few callouts so store the access token so it can be reused.
        String accessToken = getAccessToken();
        String agreementId = notification.agreement.id;
        Blob signedDocument = getSignedDocument(accessToken, agreementId);
        string formFieldsCSV = getFormFields(accessToken, agreementId);

        /** callouts are done now process **/


        // insert the document and link
        insert new Attachment(
            ParentId = agreement.Id,
            Name = notification.agreement.name,
            Body = signedDocument,
            ContentType = 'application/pdf'
        );


        // get the form field Mappings to map values
        List<echosign_dev1__SIGN_Field_Mapping__c> fieldMappings = getFormFieldMappings(agreement.echosign_dev1__Process_Template__c);

        // find the parent lead and update values if there are field mappings
        if (!fieldMappings.isEmpty() && agreement.CustomConsumer__c != NULL) { 
            updateParentLead(fieldMappings, formFieldsCSV, agreement.CustomConsumer__c, agreement.echosign_dev1__Process_Template__c);
        }

        EventBus.publish(new Agreement_Update_MVN__e(
            Agreement_MVN__c = agreement.Id,
            Status_MVN__c = 'Signed'
        ));
    }

    /**
     * Retrieve the PDF of the signed document as a blob
     * @param accessToken - String
     * @param agrementId - String
     * returns Blob
     */
    private static Blob getSignedDocument(String accessToken, String agreementId) {
        HttpRequest signedDocReq = new HttpRequest();
        signedDocReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'agreements/' + agreementId + '/combinedDocument');
        signedDocReq.setMethod('GET');
        signedDocReq.setHeader('Authorization', 'Bearer ' + accessToken);

        HttpResponse signedDocResponse = new Http().send(signedDocReq);
        if (signedDocResponse.getStatusCode() != 200) {
            throw new AdobeSignApiMVNException('Error retrieving SIGNED DOCUMENT for agreement ' + agreementId);
        }

        return signedDocResponse.getBodyAsBlob();
    }

    /**
     * Retrieve the CSVsring of the signed document form fields
     * @param accessToken - String
     * @param agrementId - String
     * returns String
     */
    private static string getFormFields(String accessToken, String agreementId) {
        HttpRequest formFieldsReq = new HttpRequest();
        formFieldsReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'agreements/' + agreementId + '/formData');
        formFieldsReq.setMethod('GET');
        formFieldsReq.setHeader('Authorization', 'Bearer ' + accessToken);

        HttpResponse formFieldsResponse = new Http().send(formFieldsReq);
        if (formFieldsResponse.getStatusCode() != 200) {
            throw new AdobeSignApiMVNException('Error retrieving FORM DATA for agreement' + agreementId);
        }

        return formFieldsResponse.getBody();
    }

    /**
     * Query for the lead field mappings
     * @param processTemplateId - Data Mappings Id
     * returns List<echosign_dev1__SIGN_Field_Mapping__c>
     */
    private static List<echosign_dev1__SIGN_Field_Mapping__c> getFormFieldMappings(Id processTemplateId) {
        List<echosign_dev1__SIGN_Field_Mapping__c> fieldMappings = new List<echosign_dev1__SIGN_Field_Mapping__c>();
        if (processTemplateId != null) {
            List<echosign_dev1__SIGN_Object_Mapping__c> objectMappings = [
                SELECT 
                    Id,
                    (
                        SELECT Name, echosign_dev1__Source__c, echosign_dev1__Type__c
                        FROM echosign_dev1__Field_Mappings__r
                    )
                FROM echosign_dev1__SIGN_Object_Mapping__c
                WHERE echosign_dev1__SIGN_Data_Mapping__c = :processTemplateId
                AND Name = 'Lead'
            ];

            if (!objectMappings.isEmpty()) {
                fieldMappings = objectMappings[0].echosign_dev1__Field_Mappings__r;
            }
        }

        return fieldMappings;
    }




    /**
     * Use the field mappings and the form fields to write back to the parent lead
     * @param fieldMappings - List<echosign_dev1__SIGN_Field_Mapping__c>
     * @param formFieldCSV - String
     * @param leadId - Id
     */
    private static void updateParentLead(List<echosign_dev1__SIGN_Field_Mapping__c> fieldMappings, String formFieldsCSV, Id leadId, Id processTemplateId) {
        Set<String> leadFields = new Set<String>{ 'Id' };

        for (echosign_dev1__SIGN_Field_Mapping__c fieldMapping : fieldMappings) {
            leadFields.add(fieldMapping.Name);
        }

        List<String> csvRows = formFieldsCSV
            .replaceAll('(\r\n|\r)','\n') // normalize all line breaks
            .split('\n');  // split into rows
        
        if (csvRows.size() != 2) {
            System.debug('CSV returned was not the expected 2 rows... something is not right');
            return;
        }

        // the header keeps the double quotes around values
        List<String> headers = csvRows[0].split(',');
        // actual values need double quotes removed
        List<String> rowdata = csvRows[1].removeStart('"').removeEnd('"').split('","'); 
        
        Map<String, Integer> headerToIndex = new Map<String, Integer>();
        for (Integer i=0; i<headers.size(); i++) {
            headerToIndex.put(headers[i], i);
        }

        Lead consumer = Database.query(
            'SELECT ' + String.join(new List<String>(leadFields), ', ') + ' ' +
            'FROM Lead WHERE Id = :leadId'
        );

        Lead_Update_MVN__e consumerUpdate = new Lead_Update_MVN__e(
            Consumer_MVN__c = consumer.Id,
            Process_Template_MVN__c = processTemplateId
        );

        for (echosign_dev1__SIGN_Field_Mapping__c fieldMapping : fieldMappings) {                
            if (fieldMapping.echosign_dev1__Type__c == 'Constant') {
                consumerUpdate.put(getFieldName(fieldMapping.Name),fieldMapping.echosign_dev1__Source__c);                        
            }

            if (fieldMapping.echosign_dev1__Type__c == 'EchoSign Form Field') {
                if (headerToIndex.containsKey(fieldMapping.echosign_dev1__Source__c)) {
                    Integer column = headerToIndex.get(fieldMapping.echosign_dev1__Source__c);
                    DisplayType dt = Lead.sObjectType.getDescribe().fields.getMap().get(fieldMapping.Name).getDescribe().getType();
                    if (dt == DisplayType.DATE) {
                        List<String> dateParts = rowdata[column].split('/');
                        consumerUpdate.put(getFieldName(fieldMapping.Name), Date.newInstance(
                            Integer.valueOf(dateParts[2]), 
                            Integer.valueOf(dateParts[0]), 
                            Integer.valueOf(dateParts[1])
                        ));
                    } else {
                        consumerUpdate.put(getFieldName(fieldMapping.Name), rowdata[column]);
                    }
                }
            }
        }

        insertSobjectList(JSON.serialize(new List<Lead_Update_MVN__e>{consumerUpdate}));
    }
    
    /**
     * Retrieve the current signing URLs for an agreement Id
     * @param agreementId - String
     * returns AdobeSignAPIMVN.SigningUrlResponse
     */
    public static SigningUrlResponse getSigningUrl(String agreementId) {
        HttpRequest signingUrlReq = new HttpRequest();
        signingUrlReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'agreements/' + agreementId + '/signingUrls'); 
        signingUrlReq.setMethod('GET');
        signingUrlReq.setHeader('Authorization', 'Bearer ' + getAccessToken());
        
        HttpResponse response = new Http().send(signingUrlReq);

        if (response.getStatusCode() != 200) {
            throw new AdobeSignAPIMVNException(response.getStatus() + '\n\n' + response.getBody());
        }

        return (SigningUrlResponse) JSON.deserialize(response.getBody(), SigningUrlResponse.class);
    }

    /**
     * Retrieve agreement info.
     * @param agreementId - String
     * returns String
     */
    public static Map<String, Object> getAgreement(String agreementId) {
        HttpRequest signingUrlReq = new HttpRequest();
        signingUrlReq.setEndPoint(adobeSignSettings.REST_API_Endpoint_MVN__c + 'agreements/' + agreementId); 
        signingUrlReq.setMethod('GET');
        signingUrlReq.setHeader('Authorization', 'Bearer ' + getAccessToken());
        
        HttpResponse response = new Http().send(signingUrlReq);

        if (response.getStatusCode() != 200) {
            throw new AdobeSignAPIMVNException(response.getStatus() + '\n\n' + response.getBody());
        }

        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        return bodyMap;
    }

    private static String getFieldName(String fieldName) {
        String result = fieldName + '_MVN__c';
        result = result.replace('HealthCloudGA__', '');
        result = result.replace('echosign_dev1__', '');
        result = result.replace('_MVN__c_MVN__c', '_MVN__c');
        result = result.replace('__c_MVN__c', '_MVN__c');
        return result;
    }

    @future
    public static void insertSobjectList(String jsonString){
        List<SObject> sObjectList = (List<SObject>) Json.deserialize(jsonString, List<SObject>.class);
        insert sObjectList;
    }

    public class WebHook {
        String name;
        String scope;
        String state;
        List<String> webhookSubscriptionEvents;
        WebhookUrlInfo webhookUrlInfo;
        WebhookConditionalParams webhookConditionalParams;
    }

    public class WebhookUrlInfo {
        String url;

        public WebhookUrlInfo(String url) {
            this.url = url;
        }
    }

    public class WebhookConditionalParams {
        WebhookAgreementEvents webhookAgreementEvents;

        public WebhookConditionalParams() {
            this.webhookAgreementEvents = new WebhookAgreementEvents();
        }
    }

    public class WebhookAgreementEvents { 
        Boolean includeDetailedInfo;
        Boolean includeDocumentsInfo;
        Boolean includeParticipantsInfo;
        Boolean includeSignedDocuments;
    }

    public class WebhookNotification {
        String webhookId;
        String webhookName;
        String webhookNotificationId;
        WebhookUrlInfo webhookUrlInfo;
        String webhookScope;
        List<WebhookNotificationApplicableUsers> webhookNotificationApplicableUsers;
        String event;
        String eventDate;
        String eventResourceType;
        String participantRole;
        String actionType;
        String participantUserId;
        String participantUserEmail;
        String actingUserId;
        String actingUserEmail;
        String actingUserIpAddress;
        public Agreement agreement;
    }

    public class WebhookNotificationApplicableUsers {
        String id;
        String email;
        String role;
        String payloadApplicable;
    }

    public class Agreement {
        public String id;
        public String name;
        public String status;
    }

    public class SigningUrlResponse {
        public List<SigningUrlSetInfo> signingUrlSetInfos;
    }

    public class SigningUrlSetInfo {
        public List<SigningUrl> signingUrls;
        public String signingUrlSetName;
    }

    public class SigningUrl {
        public string email;
        public string esignUrl;
    }
}