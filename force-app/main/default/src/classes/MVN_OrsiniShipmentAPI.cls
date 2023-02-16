/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Shipment API
 */
@RestResource(urlMapping='/api/orsini/shipment')
global with sharing class MVN_OrsiniShipmentAPI {

    /**
     * Orsini Shipment Request
     */
    private static List<MVN_OrsiniShipmentRequest> orsiniShipmentRequests;

    /**
     * Map of SP Patient Orsini Id By CarePlan SFDC Id
     */
    private static Map<Id, String> spPatientIdByCarePlanId;

    /**
     * Global success for all shipments
     */
    private static Boolean isSuccess;

    /**
     * HTTP Post handle method for the API to create Shipment from JSON provided
     * @return  `MVN_OrsiniShipmentResponse`
     */
    @HttpPost
    global static MVN_OrsiniShipmentResponse handleOrsiniShipmentPostAPI() {
        MVN_OrsiniShipmentResponse response = new MVN_OrsiniShipmentResponse();
        String json = RestContext.request.requestBody.toString();
        isSuccess = true;
        Savepoint savepoint =  Database.setSavepoint();
        try {
            orsiniShipmentRequests = (List<MVN_OrsiniShipmentRequest>) System.JSON.deserialize(json, List<MVN_OrsiniShipmentRequest>.class);
            if (orsiniShipmentRequests.isEmpty()) {
                throw new MVN_OrsiniShipmentAPIException(Label.MVN_Orsini_Shipment_No_Requests_Found);
            }
            Set<String> spPatientIds = getSPPatientIds();
            Map<String, Case> carePlanByAccount = getCarePlans(spPatientIds);
            List<PJN_Shipment__c> shipments = new List<PJN_Shipment__c>();
            for (MVN_OrsiniShipmentRequest orsiniShipmentRequest : orsiniShipmentRequests) {
                Case carePlan = String.IsNotBlank(orsiniShipmentRequest.sp_patient_id) && carePlanByAccount.containsKey(orsiniShipmentRequest.sp_patient_id) ?
                    carePlanByAccount.get(orsiniShipmentRequest.sp_patient_id) :
                    null;
                if (carePlan == null) {
                    continue;
                }
                shipments.add(orsiniShipmentRequest.getShipment(carePlan));
            }
            response.shipments = getShipmentInsertResults(shipments);
            response.status = isSuccess ? 'success' : 'error';
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(json, System.JSON.serialize(response));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch(Exception ex) {
            System.debug('### Orsini::Shipment::Error: ' + ex.getStackTraceString());
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
     * Get All SP Patient Ids from the request
     * @return  `Set<String>`
     */
    private static Set<String> getSPPatientIds() {
        Set<String> spPatientIds = new Set<String>();
        for (MVN_OrsiniShipmentRequest orsiniShipmentRequest : orsiniShipmentRequests) {
            if (String.IsNotBlank(orsiniShipmentRequest.sp_patient_id)) {
                spPatientIds.add(orsiniShipmentRequest.sp_patient_id);
            }
        }
        return spPatientIds;
    }

    /**
     * Get all CarePlans with an account related included the in hub Patient id provided
     * @param spPatientIds List of Hub Patient Ids
     * @return  `Map<Id, Case>`
     */
    private static Map<String, Case> getCarePlans(Set<String> spPatientIds) {
        Map<String, Case> carePlanByAccount = new Map<String, Case> ();
        spPatientIdByCarePlanId = new Map<Id, String>();
        if (spPatientIds.isEmpty()) {
            return carePlanByAccount;
        }
        for (Case carePlan : getCarePlansFromSOSL(spPatientIds)) {
            if (!spPatientIds.contains(carePlan.MVN_SP_Patient_Id__c)) {
                continue;
            }
            carePlanByAccount.put(carePlan.MVN_SP_Patient_Id__c, carePlan);
            spPatientIdByCarePlanId.put(carePlan.Id, carePlan.MVN_SP_Patient_Id__c);
        }
        return carePlanByAccount;
    }

    /**
     * Calculate the SOSL filters adapting to the char limit of 10k
     * Then execute the SOSL to obtain the records
     * @param spPatientIds  SP Patient Ids from shipments
     * @return  `List<Case>`
     */
    private static List<Case> getCarePlansFromSOSL(Set<String> spPatientIds) {
        List<String> soslFilterList = new List<String>();
        String soslFilter = '';
        for (String spPatientId : spPatientIds) {
            String temporaryFilter = soslFilter + spPatientId + ' OR ';
            if (temporaryFilter.length() >= 10000) {
                soslFilterList.add(soslFilter.substringBeforeLast(' OR '));
                soslFilter = '';
                temporaryFilter = spPatientId + ' OR ';
            }
            soslFilter = temporaryFilter;
        }
        soslFilterList.add(soslFilter.substringBeforeLast(' OR '));
        List<Case> carePlans = new List<Case>();
        for (String thisSOSLFilter : soslFilterList) {
            carePlans.addAll(getCarePlansFromSOSLUsingFilter(thisSOSLFilter));
        }
        return carePlans;
    }

    /**
     * Given a SOSL filter to query, get all careplans which match the criteria
     * @param soslFilter    SOSL Filter to query
     * @return  `List<Case>`
     */
    private static List<Case> getCarePlansFromSOSLUsingFilter(String soslFilter) {
        List<List<SObject>> soslResults = [
            FIND
                :soslFilter
            IN ALL FIELDS
            RETURNING Case(
                Id,
                AccountId,
                MVN_SP_Patient_Id__c,
                RecordType.DeveloperName
            WHERE RecordType.DeveloperName = 'CarePlan'
            ORDER BY CreatedDate ASC)
        ];
        if (soslResults.isEmpty()) {
            return new List<Case>();
        }
        return (List<Case>) soslResults[0];
    }

    /**
     * Insert all shipments and get the results in a wrapper to be returned to in the call
     * @param shipments    List of shipments to be created
     * @return  `List<MVN_OrsiniShipmentResult>`
     */
    private static List<MVN_OrsiniShipmentResult> getShipmentInsertResults(List<PJN_Shipment__c> shipments) {
        List<MVN_OrsiniShipmentResult> orsiniShipmentResults = new List<MVN_OrsiniShipmentResult>();
        List<Database.SaveResult> saveResults = Database.insert(shipments, false);
        Set<String> spPatientIds = new Set<String>();
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            PJN_Shipment__c shipment = shipments[i];
            MVN_OrsiniShipmentResult orsiniShipmentResult = new MVN_OrsiniShipmentResult();
            orsiniShipmentResult.success = saveResult.isSuccess();
            isSuccess = isSuccess && saveResult.isSuccess();
            orsiniShipmentResult.sp_patient_id = spPatientIdByCarePlanId.get(shipment.PJN_Care_Plan__c);
            spPatientIds.add(orsiniShipmentResult.sp_patient_id);
            if (saveResult.isSuccess()) {
                orsiniShipmentResult.shipment_id = shipment.Id;
            } else {
                orsiniShipmentResult.message = saveResult.getErrors()[0].message;
            }
            orsiniShipmentResults.add(orsiniShipmentResult);
        }
        orsiniShipmentResults.addAll(getNoFoundRequests(spPatientIds));
        return orsiniShipmentResults;
    }

    /**
     * Get requests with no record related in the system to notify in the call response
     * @param spPatientIds
     * @return  `List<MVN_OrsiniShipmentResult>`
     */
    private static List<MVN_OrsiniShipmentResult> getNoFoundRequests(Set<String> spPatientIds) {
        List<MVN_OrsiniShipmentResult> noFoundShipments = new List<MVN_OrsiniShipmentResult>();
        for (MVN_OrsiniShipmentRequest orsiniShipmentRequest : orsiniShipmentRequests) {
            if (String.IsNotBlank(orsiniShipmentRequest.sp_patient_id) && !spPatientIds.contains(orsiniShipmentRequest.sp_patient_id)) {
                MVN_OrsiniShipmentResult orsiniShipmentResult = new MVN_OrsiniShipmentResult();
                orsiniShipmentResult.sp_patient_id = orsiniShipmentRequest.sp_patient_id;
                orsiniShipmentResult.success = false;
                orsiniShipmentResult.message = Label.MVN_Orsini_Shipment_No_Patient_Or_CarePlan_Found;
                noFoundShipments.add(orsiniShipmentResult);
                isSuccess = false;
            }
        }
        return noFoundShipments;
    }

    /**
     * Orsini Status API Exception Handler
     */
    public class MVN_OrsiniShipmentAPIException extends System.Exception{}
}