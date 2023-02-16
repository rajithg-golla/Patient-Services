/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Status API
 */
@RestResource(urlMapping='/api/orsini/status')
global with sharing class MVN_OrsiniStatusAPI {

    /**
     * Orsini Status Request
     */
    private static List<MVN_OrsiniStatusRequest> orsiniStatusRequests;

    /**
     * Map of Hub Patient Orsini Id By CarePlan SFDC Id
     */
    private static Map<Id, String> hubPatientIdByCarePlanId;

    /**
     * Global success for all events
     */
    private static Boolean isSuccess;

    /**
     * HTTP Post handle method for the API to create Event from JSON provided
     * @return  `MVN_OrsiniStatusResponse`
     */
    @HttpPost
    global static MVN_OrsiniStatusResponse handleOrsiniStatusPostAPI() {
        MVN_OrsiniStatusResponse response = new MVN_OrsiniStatusResponse();
        String json = RestContext.request.requestBody.toString();
        isSuccess = true;
        Savepoint savepoint =  Database.setSavepoint();
        try {
            orsiniStatusRequests = (List<MVN_OrsiniStatusRequest>) System.JSON.deserialize(json, List<MVN_OrsiniStatusRequest>.class);
            if (orsiniStatusRequests.isEmpty()) {
                throw new MVN_OrsiniStatusAPIException(Label.MVN_Orsini_Status_No_Requests);
            }
            Set<String> hubPatientIds = getHubPatientIds();
            Map<String, Case> carePlanByAccount = getCarePlans(hubPatientIds);
            List<PJN_Event__c> events = new List<PJN_Event__c>();
            Map<Id, Case> carePlansToUpdateById = new Map<Id, Case>();
            for (MVN_OrsiniStatusRequest orsiniStatusRequest : orsiniStatusRequests) {
                Case carePlan = String.IsNotBlank(orsiniStatusRequest.hub_patient_id) && carePlanByAccount.containsKey(orsiniStatusRequest.hub_patient_id) ?
                    carePlanByAccount.get(orsiniStatusRequest.hub_patient_id) :
                    null;
                if (carePlan == null) {
                    continue;
                }
                PJN_Event__c currentEvent = orsiniStatusRequest.getEvent(carePlan);
                events.add(currentEvent);
                carePlan.MVN_SP_Patient_Id__c = currentEvent.PJN_SP_Patient_Id__c;
                carePlansToUpdateById.put(carePlan.Id, carePlan);
            }
            response.events = getEventInsertResults(events);
            response.status = isSuccess ? 'success' : 'error';
            if (!carePlansToUpdateById.isEmpty()) {
                update carePlansToUpdateById.values();
            }
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(json, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch(Exception ex) {
            System.debug('### Orsini::Status::Error: ' + ex.getStackTraceString());
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
     * Get All Hub Patient Ids from the request
     * @return  `Set<String>`
     */
    private static Set<String> getHubPatientIds() {
        Set<String> hubPatientIds = new Set<String>();
        for (MVN_OrsiniStatusRequest orsiniStatusRequest : orsiniStatusRequests) {
            if (String.IsNotBlank(orsiniStatusRequest.hub_patient_id)) {
                hubPatientIds.add(orsiniStatusRequest.hub_patient_id);
            }
        }
        return hubPatientIds;
    }

    /**
     * Get all CarePlans with an account related included the in hub Patient id provided
     * @param hubPatientIds List of Hub Patient Ids
     * @return  `Map<Id, Case>`
     */
    private static Map<String, Case> getCarePlans(Set<String> hubPatientIds) {
        Map<String, Case> carePlanByAccount = new Map<String, Case> ();
        hubPatientIdByCarePlanId = new Map<Id, String>();
        for (Case carePlan : [
            SELECT
                Id,
                AccountId,
                MVN_SP_Patient_Id__c,
                Account.MVN_Patient_Id__c,
                PJN_Program_DeveloperName__c
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'CarePlan'
            AND
                Account.MVN_Patient_Id__c IN :hubPatientIds
            ORDER BY
                CreatedDate ASC
        ]) {
            carePlanByAccount.put(carePlan.Account.MVN_Patient_Id__c, carePlan);
            hubPatientIdByCarePlanId.put(carePlan.Id, carePlan.Account.MVN_Patient_Id__c);
        }
        return carePlanByAccount;
    }

    /**
     * Insert all Events and get the results in a wrapper to be returned to in the call
     * @param events    List of Events to be created
     * @return  `List<MVN_OrsiniEventResult>`
     */
    private static List<MVN_OrsiniEventResult> getEventInsertResults(List<PJN_Event__c> events) {
        List<MVN_OrsiniEventResult> orsiniEventResults = new List<MVN_OrsiniEventResult>();
        List<Database.SaveResult> saveResults = Database.insert(events, false);
        Set<String> hubPatientIds = new Set<String>();
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            PJN_Event__c event = events[i];
            MVN_OrsiniEventResult orsiniEventResult = new MVN_OrsiniEventResult();
            orsiniEventResult.success = saveResult.isSuccess();
            isSuccess = isSuccess && saveResult.isSuccess();
            orsiniEventResult.hub_patient_id = hubPatientIdByCarePlanId.get(event.PJN_Case__c);
            hubPatientIds.add(orsiniEventResult.hub_patient_id);
            if (saveResult.isSuccess()) {
                orsiniEventResult.event_id = event.Id;
            } else {
                orsiniEventResult.message = saveResult.getErrors()[0].message;
            }
            orsiniEventResults.add(orsiniEventResult);
        }
        orsiniEventResults.addAll(getNoFoundRequests(hubPatientIds));
        return orsiniEventResults;
    }

    /**
     * Get requests with no record related in the system to notify in the call response
     * @param hubPatientIds
     * @return  `List<MVN_OrsiniEventResult>`
     */
    private static List<MVN_OrsiniEventResult> getNoFoundRequests(Set<String> hubPatientIds) {
        List<MVN_OrsiniEventResult> noFoundEvents = new List<MVN_OrsiniEventResult>();
        for (MVN_OrsiniStatusRequest orsiniStatusRequest : orsiniStatusRequests) {
            if (String.IsNotBlank(orsiniStatusRequest.hub_patient_id) && !hubPatientIds.contains(orsiniStatusRequest.hub_patient_id)) {
                MVN_OrsiniEventResult orsiniEventResult = new MVN_OrsiniEventResult();
                orsiniEventResult.hub_patient_id = orsiniStatusRequest.hub_patient_id;
                orsiniEventResult.success = false;
                orsiniEventResult.message = Label.MVN_Orsini_Status_No_Patient_Or_CarePlan_Found;
                noFoundEvents.add(orsiniEventResult);
                isSuccess = false;
            }
        }
        return noFoundEvents;
    }

    /**
     * Orsini Status API Exception Handler
     */
    public class MVN_OrsiniStatusAPIException extends System.Exception{}
}