/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Patient API
 * Note: All the methods related with the sending of files have been commented 
 * because of the heap size limit that we were hitting. 
 * Files are going to be sent in a different way
 */
@RestResource(urlMapping='/api/orsini/patient')
global with sharing class MVN_OrsiniPatientAPI {

    /**
     * Orsini Patient Request
     */
    private static List<MVN_OrsiniPatientRequest> orsiniPatientRequests;

    /**
     * HTTP Get handle method for the API to retrieve all Submitted Fulfillment Requests
     * @return  `MVN_OrsiniPatientResponse`
     */
    @HttpGet
    global static MVN_OrsiniPatientResponse handleOrsiniPatientGetAPI() {
        MVN_OrsiniPatientResponse response = new MVN_OrsiniPatientResponse();
        Savepoint savepoint =  Database.setSavepoint();
        try {
            List<PJN_Fulfillment_Request__c> fulfillmentRequests = getFulfillmentRequests();
            // Commenting this because of the heap size limit that we were hitting, files are going to be sent in a different way
            // Map<Id, List<ContentVersion>> filesByFulfillmentId = getFulfillmentFiles(fulfillmentRequests);
            response.fulfillments = new List<MVN_OrsiniPatientFulfillment>();
            List<PJN_Fulfillment_Request__c> fulfillmentRequestsToUpdate = new List<PJN_Fulfillment_Request__c>();
            for (PJN_Fulfillment_Request__c fulfillmentRequest : fulfillmentRequests) {
                MVN_OrsiniPatientFulfillment orsiniFulfillment = new MVN_OrsiniPatientFulfillment(fulfillmentRequest);
                Datetime currentDatetime = System.now();
                // Commenting this because of the heap size limit that we were hitting, files are going to be sent in a different way
                // if (filesByFulfillmentId.containsKey(fulfillmentRequest.Id)) {
                //     orsiniFulfillment.addFiles(filesByFulfillmentId.get(fulfillmentRequest.Id));
                // }
                response.fulfillments.add(orsiniFulfillment);
                fulfillmentRequestsToUpdate.add(
                    new PJN_Fulfillment_Request__c (
                        Id = fulfillmentRequest.Id,
                        PJN_Fulfillment_Request_Status__c = Label.MVN_Orsini_Patient_Status_Processed
                    )
                );
            }
            response.status = 'success';
            update fulfillmentRequestsToUpdate;
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(null, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch(Exception ex) {
            System.debug('### Orsini::TriageRequest::Error: ' + ex.getStackTraceString());
            response.status = 'error';
            response.message = ex.getMessage();
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(null, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addError(transactionLog);
            Database.rollback(savepoint);
        } finally {
            PJN_PublishTransactionLog.publish();
        }
        return response;
    }

    /**
     * Http Post handle method for the API to update Fulfillment Request provided with status and message
     * @return  `MVN_OrsiniPatientResponse`
     */
    @HttpPost
    global static MVN_OrsiniPatientResponse handleOrsiniPatientPostAPI() {
        MVN_OrsiniPatientResponse response = new MVN_OrsiniPatientResponse();
        String json = RestContext.request.requestBody.toString();
        Savepoint savepoint =  Database.setSavepoint();
        try {
            orsiniPatientRequests = (List<MVN_OrsiniPatientRequest>) System.JSON.deserialize(json, List<MVN_OrsiniPatientRequest>.class);
            Set<String> fulfillmentIds = getFulfillmentIds();
            Map<Id, PJN_Fulfillment_Request__c> fulfillmentRequestsMap = getFulfillmentRequests(fulfillmentIds);
            List<PJN_Fulfillment_Request__c> fulfillmentRequests = new List<PJN_Fulfillment_Request__c>();
            for (MVN_OrsiniPatientRequest orsiniPatientRequest : orsiniPatientRequests) {
                Boolean existFulfillment = String.IsNotBlank(orsiniPatientRequest.fulfillment_request_id) && fulfillmentRequestsMap.containsKey(orsiniPatientRequest.fulfillment_request_id);
                if (!existFulfillment) {
                    continue;
                }
                fulfillmentRequests.add(
                    new PJN_Fulfillment_Request__c(
                        Id = orsiniPatientRequest.fulfillment_request_id,
                        MVN_SP_Patient_Triage_Status__c = orsiniPatientRequest.status,
                        MVN_SP_Patient_Triage_Error__c = orsiniPatientRequest.message
                    )
                );
            }
            response.status = 'success';
            update fulfillmentRequests;
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(json, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch(Exception ex) {
            System.debug('### Orsini::TriageResponse::Error: ' + ex.getStackTraceString());
            response.status = 'error';
            response.message = ex.getMessage();
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(json, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addError(transactionLog);
            Database.rollback(savepoint);
        } finally {
            PJN_PublishTransactionLog.publish();
        }
        return response;
    }

    /**
     * Get all submitted fulfillment requests
     * @return  `List<PJN_Fulfillment_Request__c>`
     */
    private static List<PJN_Fulfillment_Request__c> getFulfillmentRequests() {
        Map<String, Schema.SObjectField> sobjectFields = Schema.SObjectType.PJN_Fulfillment_Request__c.fields.getMap();
        String fieldNames = '';
        for(String fieldName : sobjectFields.keySet()) {
            fieldNames += fieldName + ',';
        }
        fieldNames = fieldNames.substringBeforeLast(',');
        String query = 'SELECT ' + fieldNames + ' FROM PJN_Fulfillment_Request__c WHERE RecordType.DeveloperName = \'MVN_SP_Triage_Submitted\' AND PJN_Fulfillment_Request_Status__c = \'' + Label.MVN_Orsini_Patient_Status_Submitted + '\'';
        return (List<PJN_Fulfillment_Request__c>) Database.query(query);
    }

    /**
     * Get Fulfillment Files by Fulfillment Ids using the fulfillments to get all related files
     * @param fulfillmentRequests   Fulfillment Requests
     * @return  `Map<Id, List<ContentVersion>>`
     */
    /*
    private static Map<Id, List<ContentVersion>> getFulfillmentFiles(List<PJN_Fulfillment_Request__c> fulfillmentRequests) {
        Map<Id, Set<Id>> linkedEntitiesByContentDocumentId = getLinkedEntitiesByContentDocumentId(fulfillmentRequests);
        Map<Id, List<ContentVersion>> contentVersionsByFulfillmentId = new Map<Id, List<ContentVersion>>();
        for (ContentVersion cv : getContentVersions(linkedEntitiesByContentDocumentId.keySet())) {
            Set<Id> linkedEntities = linkedEntitiesByContentDocumentId.get(cv.ContentDocumentId);
            if (linkedEntities == null || linkedEntities.isEmpty()) {
                continue;
            }
            for (Id linkedEntity : linkedEntities) {
                List<ContentVersion> currentCVs = contentVersionsByFulfillmentId.containsKey(linkedEntity) ?
                    contentVersionsByFulfillmentId.get(linkedEntity) :
                    new List<ContentVersion>();
                currentCVs.add(cv);
                contentVersionsByFulfillmentId.put(linkedEntity, currentCVs);
            }
        }
        return contentVersionsByFulfillmentId;
    }
    */

    /**
     * Get Fulfillment Request Ids by Content Document Id to be able to relate the Content Version with the Fulfillment
     * @param fulfillmentRequests   Fulfillment Requests
     * @return  `Map<Id, Set<Id>>`
     */
    /*
    private static Map<Id, Set<Id>> getLinkedEntitiesByContentDocumentId(List<PJN_Fulfillment_Request__c> fulfillmentRequests) {
        Map<Id, Set<Id>> linkedEntitiesByContentDocumentId = new Map<Id, Set<Id>>();
        for (ContentDocumentLink cdl : getContentDocumentLinks(fulfillmentRequests)) {
            Set<Id> linkedEntities = linkedEntitiesByContentDocumentId.containsKey(cdl.ContentDocumentId) ?
                linkedEntitiesByContentDocumentId.get(cdl.ContentDocumentId) :
                new Set<Id>();
            linkedEntities.add(cdl.LinkedEntityId);
            linkedEntitiesByContentDocumentId.put(cdl.ContentDocumentId, linkedEntities);
        }
        return linkedEntitiesByContentDocumentId;
    }
    */

    /**
     * Get Content Document Links related to the Fulfillment Requests provided
     * @param fulfillmentRequests   Fulfillment Requests
     * @return  `List<ContentDocumentLink>`
     */
    /*
    private static List<ContentDocumentLink> getContentDocumentLinks(List<PJN_Fulfillment_Request__c> fulfillmentRequests) {
        Set<Id> linkedEntityIds = new Set<Id>();
        for (PJN_Fulfillment_Request__c fulfillmentRequest : fulfillmentRequests) {
            linkedEntityIds.add(fulfillmentRequest.Id);
        }
        if (linkedEntityIds.isEmpty()) {
            return new List<ContentDocumentLink>();
        }
        return [
            SELECT
                ContentDocumentId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId IN :linkedEntityIds
        ];
    }
    */

    /**
     * Get All the Content Versions related to the ContentDocuments related to the Fulfillment Requests
     * @param contentDocumentIds    Content Document Ids
     * @return  `List<ContentVersion>`
     */
    /*
    private static List<ContentVersion> getContentVersions(Set<Id> contentDocumentIds) {
        return [
            SELECT
                Id,
                ContentSize,
                Description,
                FileExtension,
                FileType,
                IsLatest,
                IsMajorVersion,
                Title,
                VersionData,
                ContentDocumentId,
                PathOnClient
            FROM
                ContentVersion
            WHERE
                ContentDocumentId IN :contentDocumentIds
            AND
                IsLatest = true
        ];
    }
    */

    /**
     * Get All fulfillment Request Ids provided in the call
     * @return  `Set<String>`
     */
    private static Set<String> getFulfillmentIds() {
        Set<String> fulfillmentIds = new Set<String>();
        for (MVN_OrsiniPatientRequest orsiniPatientRequest : orsiniPatientRequests) {
            if (String.IsNotBlank(orsiniPatientRequest.fulfillment_request_id)) {
                fulfillmentIds.add(orsiniPatientRequest.fulfillment_request_id);
            }
        }
        return fulfillmentIds;
    }

    /**
     * Get Fulfillment Request records from the ids provided
     * @param fulfillmentIds
     * @return  `Map<Id, PJN_Fulfillment_Request__c>`
     */
    private static Map<Id, PJN_Fulfillment_Request__c> getFulfillmentRequests(Set<String> fulfillmentIds) {
        return new Map<Id, PJN_Fulfillment_Request__c> (
            [
                SELECT
                    Id
                FROM
                    PJN_Fulfillment_Request__c
                WHERE
                    Id IN :fulfillmentIds
            ]
        );
    }
}