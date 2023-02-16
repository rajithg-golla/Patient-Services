/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the MVN_ConnectiveRxEnrollment sending enrollments to ConnectiveRx
 */
public with sharing class MVN_ConnectiveRxEnrollment {

    /**
     * Enrollment Response
     */
    private static MVN_ConnectiveRxEnrollResponse crxEnrollResponse;

    /**
     * LWC action to send the enrollment to ConnectiveRx
     * @param recordId  Fulfillment Request Id
     * @return  `Boolean`
     * @exception       AuraHandledException
     */
    @AuraEnabled
    public static Map<String, Object> sendEnrollment(String recordId){
        Map<String, Object> result = new Map<String, Object>();
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest(recordId);

        String validatePhoneException = validatePhoneLength(fulfillment);
        if (!String.isBlank(validatePhoneException)) {
            throw new AuraHandledException(validatePhoneException);
        }

        String requestBody = getRequestBody(fulfillment);
        try {
            HttpRequest request = getConnectiveRxRequest('enroll');
            request.setBody(requestBody);
            crxEnrollResponse = callConnectiveRx(request);
            if (crxEnrollResponse.success) {
                updateCopayCard(fulfillment);
            }
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(System.JSON.serializePretty(requestBody), System.JSON.serializePretty(crxEnrollResponse));
            PJN_PublishTransactionLog.addDebug(transactionLog);
            result.put('success', crxEnrollResponse.success);
            result.put('message', crxEnrollResponse.message);
        } catch (Exception ex) {
            System.debug('### CRX::Enrollment::Error: ' + ex.getStackTraceString());
            result.put('success', false);
            result.put('message', ex.getMessage());
            String transactionLogErrorMessage = crxEnrollResponse != null ? System.JSON.serializePretty(crxEnrollResponse) : String.valueOf(result.get('message'));
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(System.JSON.serializePretty(requestBody), transactionLogErrorMessage);
            PJN_PublishTransactionLog.addError(transactionLog);
        } finally {
            PJN_PublishTransactionLog.publish();
        }
        if (!Boolean.valueOf(result.get('success')) && !Test.isRunningTest()) {
            throw new AuraHandledException(String.valueOf(result.get('message')));
        }
        return result;
    }

    /**
     * Get Request Body as JSON serialized enrollment
     * @param fulfillment   Fulfillment Request record
     * @return  `String`
     */
    private static String getRequestBody(PJN_Fulfillment_Request__c fulfillment) {
        MVN_ConnectiveRxEnrollRequest crxEnrollRequest = new MVN_ConnectiveRxEnrollRequest(fulfillment);
        String requestBody = System.JSON.serialize(crxEnrollRequest, true);
        requestBody = requestBody.replaceAll('"mvn_connectiverx_', '"');
        System.debug('*** Request body: ' + requestBody);
        return requestBody;
    }

    /**
     * Get Fulfillment Request from the database using the record id
     * @param recordId  Fulfillment Request Id
     * @return  `PJN_Fulfillment_Request__c`
     */
    private static PJN_Fulfillment_Request__c getFulfillmentRequest(String recordId) {
        Map<String, Schema.SObjectField> sobjectFields = Schema.SObjectType.PJN_Fulfillment_Request__c.fields.getMap();
        String fieldNames = '';
        for(String fieldName : sobjectFields.keySet()) {
            fieldNames += fieldName + ',';
        }
        fieldNames = fieldNames.substringBeforeLast(',');
        String query = 'SELECT ' + fieldNames + ' FROM PJN_Fulfillment_Request__c WHERE Id = :recordId';
        return (PJN_Fulfillment_Request__c) Database.query(query);
    }
        
    /**
     * @description Validate then length of the phone fields. ConnectiveRX only accepts 10 digits.
     * @param  fulfillment Fulfillment Request record
     * @return String  
     */ 
    private static String validatePhoneLength(PJN_Fulfillment_Request__c fulfillment) {
        String exc = '';
        if (fulfillment.PJN_Physician_Phone__c != null && fulfillment.PJN_Physician_Phone__c.length() > 10) {
            exc += Label.MVN_CRX_Physician_Phone_Validation_error + '; ';
        }
        if (fulfillment.PJN_Patient_Phone__c != null && fulfillment.PJN_Patient_Phone__c.length() > 10) {
            exc += Label.MVN_CRX_Patient_Phone_Validation_error;
        }
        return exc;
    }

    /**
     * Get ConnectionRx Request for the endpoint method provided
     * @param endpoint  ConnectiveRX endpoint method
     * @return  `HttpRequest`
     */
    private static HttpRequest getConnectiveRxRequest(String endpoint) {
        HttpRequest req = new HttpRequest();
        String thisEndpoint = 'callout:MVN_ConnectiveRx_API/' + endpoint;
        req.setEndpoint(thisEndpoint);
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setHeader('x-api-key', '{!$Credential.Password}');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }

    /**
     * Call ConnectiveRx sending request body to corresponding endpoint
     * @param request   Connective Rx Request
     * @return  `MVN_ConnectiveRxEnrollResponse`
     */
    private static MVN_ConnectiveRxEnrollResponse callConnectiveRx(HttpRequest request) {
        Http h = new Http();
        HttpResponse response = h.send(request);
        System.debug('*** Response: ' + response);
        System.debug('*** Response body: ' + response.getBody());
        crxEnrollResponse = (MVN_ConnectiveRxEnrollResponse) System.JSON.deserialize(response.getBody(), MVN_ConnectiveRxEnrollResponse.class);
        if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            handleConnectiveRxError(response.getStatusCode());
        }
        return crxEnrollResponse;
    }

    /**
     * Update Copay card in Fulfillment Request and Assistance Program
     * Assistance Program needs to be related to the CarePlan.
     * If no Assistance Program, ignores the Assistance Program update.
     * @param fulfillment   Fulfillment Request to be updated
     */
    private static void updateCopayCard(PJN_Fulfillment_Request__c fulfillment) {
        PJN_Assistance_Program__c assistanceProgram = getAssistanceProgram(fulfillment.PJN_Care_Plan__c);
        fulfillment = crxEnrollResponse.result.getFulfillmentUpdated(fulfillment);
        if (assistanceProgram != null) {
            assistanceProgram = crxEnrollResponse.result.getAssistanceProgram(assistanceProgram);
            update assistanceProgram;
        }
        update fulfillment;
    }

    /**
     * Get Assistance Program using CarePlan
     * @param carePlanId    CarePlan id
     * @return  `PJN_Assistance_Program__c`
     */
    private static PJN_Assistance_Program__c getAssistanceProgram(Id carePlanId) {
        List<PJN_Assistance_Program__c> assistancePrograms = [
            SELECT
                Id
            FROM
                PJN_Assistance_Program__c
            WHERE
                PJN_Care_Plan__c = :carePlanId
            AND
                RecordType.DeveloperName = 'PJN_Copay'
        ];
        return !assistancePrograms.isEmpty() ? assistancePrograms[0] : null;
    }

    /**
     * Handle ConnectiveRx Error
     * @param statusCode    ConnectiveRx Error status code
     * @exception
     */
    private static void handleConnectiveRxError(Integer statusCode) {
        String errorMessage = crxEnrollResponse.message;
        if (crxEnrollResponse.errors != null && !crxEnrollResponse.errors.isEmpty()) {
            for (MVN_ConnectiveRxEnrollError crxEnrollError : crxEnrollResponse.errors) {
                errorMessage += '; ' + crxEnrollError.message;
            }
        }
        System.debug('### ConnectiveRx::Enrollment - Error code: ' + statusCode + ', Message: ' + errorMessage);
        throw new APL_ConnectiveRxException(errorMessage);
    }

    /**
     * Exception handler
     */
    public class APL_ConnectiveRxException extends System.Exception{}
}