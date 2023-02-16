/**
 * @author      Mavens
 * @group       DataLake
 * @description Queue DataLake Payer Callout to retrieve all the data
 *              Divide all work between queue jobs of 2000 records max to avoid SFDC limit errors
 */
public with sharing class MVN_DataLakePayerMasterQueue implements Queueable, Database.AllowsCallouts {

    /**
     * MDM Connection
     */
    private static MVN_MDM_Connection__mdt mdmConnection = MVN_MDMConnectionUtil.getConnectionByName('MVN_DataLake_Payer');

    /**
     * DataLake Payer Master list
     */
    public List<MVN_DataLakePayerMaster> dataLakePayers;

    /**
     * Constructor to initialize DataLake Payers
     * @param dataLakePayers    List of DataLake Payers
     */
    public MVN_DataLakePayerMasterQueue(List<MVN_DataLakePayerMaster> dataLakePayers) {
        this.dataLakePayers = dataLakePayers;
    }

    /**
     * Queue execute to obtain the datalake payers if need it
     * Add or edit 2000 payers max using External id
     * Queue next job with the rest of payers if still have unprocessed payers
     * @param context   Queue context
     */
    public void execute(QueueableContext context) {
        initDataLakePayers();
        if (this.dataLakePayers.isEmpty()) {
            return;
        }
        Map<String, Account> payerByExternalId = new Map<String, Account>();
        Map<String, MVN_Payer_Plan__c> payerPlanByExternalId = new Map<String, MVN_Payer_Plan__c>();
        Integer minSize = dataLakePayers.size() - 2000 < 0 ? 0 : dataLakePayers.size() - 2000;
        for (Integer i = dataLakePayers.size() - 1; i >= minSize; i--) {
            MVN_DataLakePayerMaster dataLakePayer = dataLakePayers.remove(i);
            Account payer = dataLakePayer.getPayerRecord();
            MVN_Payer_Plan__c payerPlan = dataLakePayer.getPayerPlanRecord();
            payerByExternalId.put(payer.MVN_Precision_Id__c, payer);
            payerPlanByExternalId.put(payerPlan.MVN_Precision_Id__c, payerPlan);
        }
        upsert payerByExternalId.values() MVN_Precision_Id__c;
        upsert payerPlanByExternalId.values() MVN_Precision_Id__c;
        if (!this.dataLakePayers.isEmpty()) {
            System.enqueueJob(new MVN_DataLakePayerMasterQueue(this.dataLakePayers));
        }
    }

    /**
     * Get all DataLake Payers if need it
     */
    private void initDataLakePayers() {
        if (this.dataLakePayers == null || this.dataLakePayers.isEmpty()) {
            this.dataLakePayers = getDataLakePayers();
        }
    }

    /**
     * Call DataLake Payer Master to return all the payers stored there
     * @return  `List<MVN_DataLakePayerMaster>`
     */
    private static List<MVN_DataLakePayerMaster> getDataLakePayers() {
        List<MVN_DataLakePayerMaster> datalakePayers = new List<MVN_DataLakePayerMaster>();
        String currentEnvironment = mdmConnection != null && String.IsNotBlank(mdmConnection.MVN_Environment__c) ?
            mdmConnection.MVN_Environment__c + '.' :
            '';
        String cmSearchQuery = 'SELECT * FROM ' + currentEnvironment + 'data_precision_payer_spine_vw';
        try {
            HttpRequest request = getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = callDataLake(request);
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, System.JSON.serializePretty(datalakeResponse));
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                Integer noFoundCounter = 0;
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('plan_id') && dtRecord.containsKey('plan')) {
                        String dlPayerJSON = System.JSON.serialize(dtRecord);
                        datalakePayers.add((MVN_DataLakePayerMaster) System.JSON.deserialize(dlPayerJSON, MVN_DataLakePayerMaster.class));
                    } else {
                        noFoundCounter++;
                    }
                }
                if (noFoundCounter > 0) {
                    transactionLog.PJN_Message__c = String.format(
                        Label.MVN_DataLake_Items_Wrong_Format_Error_Message,
                        new List<String> {
                            String.valueOf(noFoundCounter)
                        }
                    );
                    PJN_PublishTransactionLog.addError(transactionLog);
                } else {
                    PJN_PublishTransactionLog.addDebug(transactionLog);
                }
            } else {
                transactionLog.PJN_Message__c = Label.MVN_DataLake_No_Items_Error_Message;
                PJN_PublishTransactionLog.addError(transactionLog);
            }
        } catch (Exception ex) {
            System.debug('### DataLake::CM::Search::Error: ' + ex.getStackTraceString());
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, ex.getMessage());
            PJN_PublishTransactionLog.addError(transactionLog);
        } finally {
            PJN_PublishTransactionLog.publish();
        }
        return datalakePayers;
    }

    /**
     * Get DataLake Request using query for the body
     * @param query Query which will obtain AWS Lambda to send into Athena
     * @return  `HttpRequest`
     */
    public static HttpRequest getDataLakeRequest(String query) {
        HttpRequest req = new HttpRequest();
        String thisEndpoint = 'callout:MVN_DataLake_API/search';
        req.setEndpoint(thisEndpoint);
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setHeader('x-api-key', '{!$Credential.Password}');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        Map<String, String> body = new Map<String, String> {
            'query' => query
        };
        System.debug('*** QUERY: ' + System.JSON.serializePretty(query));
        req.setBody(System.JSON.serialize(body));
        return req;
    }

    /**
     * Call DataLake sending request body to corresponding endpoint
     * @param request   DataLake Request
     * @return  `Map<String, Object>`
     */
    public static Map<String, Object> callDataLake(HttpRequest request) {
        Http h = new Http();
        HttpResponse response = h.send(request);
        System.debug('*** Response: ' + response);
        System.debug('*** Response body: ' + response.getBody());
        Map<String, Object> datalakeResponse = (Map<String, Object>) System.JSON.deserializeUntyped(response.getBody());
        System.debug('*** Response deserialized: ' + System.JSON.serializePretty(datalakeResponse));
        if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            System.debug('*** Error response: ' + response);
            System.debug('*** Error: ' + datalakeResponse);
        }
        return datalakeResponse;
    }
}