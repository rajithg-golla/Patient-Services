/**
 * @author Mavens
 * @description Connector to Veeva CRM for Enrollment integration.
 */
public without sharing class PJN_VeevaCRMEnrollmentConnector implements PJN_ICRMEnrollmentConnector {

    PJN_CRM_Connection_Setting__mdt connectionSetting;
    Map<Id, PJN_Event__c> eventMap;

    public PJN_VeevaCRMEnrollmentConnector() { // NOPMD - no arg constructor for dynamically calling
    }

    /**
     * @param events
     * @returns `String`
     */
    public Map<String, String> mapEvents(PJN_EventToCRMHdlr.ConnectionWrapper wrapper) {
        connectionSetting = wrapper.connectionSetting;
        eventMap = wrapper.eventMap;
        Map<Id, Account> eventToPatientMap = buildEventToPatientMap();
        Map<Id, String> accountIdToVeevaNetworkId = buildIdToNetworkIdMap();
        Map<Id, String> caseExternalIds = getExistingExternalIds();

        List<PJN_VeevaCRMEnrollment> enrollments = new List<PJN_VeevaCRMEnrollment>();
        List<PJN_VeevaCRMStatus> statuses = new List<PJN_VeevaCRMStatus>();

        for (PJN_Event__c event : eventMap.values()) {
            if (caseExternalIds.containsKey(event.PJN_Case__c)) {
                statuses.add(new PJN_VeevaCRMStatus(event, accountIdToVeevaNetworkId));
            } else {
                enrollments.add(new PJN_VeevaCRMEnrollment(event, accountIdToVeevaNetworkId, eventToPatientMap.containsKey(event.Id) ? eventToPatientMap.get(event.Id) : NULL));
                statuses.add(new PJN_VeevaCRMStatus(event, accountIdToVeevaNetworkId));
            }
        }

        Map<String, String> result = new Map<String, String>();
        if (enrollments.size() > 0) {
            result.put('PJN_Enrollment__c', PJN_VeevaCRMConnectionUtility.createJsonString(convertToObjects(enrollments)));
            result.put('PJN_Enrollment_Status__c', PJN_VeevaCRMConnectionUtility.createJsonString(convertToObjects(statuses)));
        } else if (statuses.size() > 0) {
            result.put('PJN_Enrollment_Status__c', PJN_VeevaCRMConnectionUtility.createJsonString(convertToObjects(statuses)));
        }

        return result;
    }

    public List<SOBject> sendToCRM(Map<String, String> jsonEnrollmentStatusMap) {
        try {
            List<SObject> results = new List<SObject>();
            for (String sObjectType : jsonEnrollmentStatusMap.keySet()) {
                HTTPResponse remoteVeevaOrgResponse = PJN_VeevaCRMConnectionUtility.calloutRemoteCrm('PATCH', 'callout:' + connectionSetting.PJN_Named_Credential__c + '/services/data/v49.0/composite/sobjects/' + sObjectType + '/PJN_External_Id__c', jsonEnrollmentStatusMap.get(sObjectType));
                results.addAll(responseParser(remoteVeevaOrgResponse));
            }
            return results;
        } catch (Exception e) {
            System.debug(e);
        }

        return new List<PJN_Event__c>();
    }

    private Map<Id, Account> buildEventToPatientMap() {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Id>> accountToEventIdMap = new Map<Id, List<Id>>();

        for (PJN_Event__c event : eventMap.values()) {
            accountIds.add(event.PJN_Patient__c);
            if (accountToEventIdMap.containsKey(event.PJN_Patient__c)) {
                List<Id> idList = accountToEventIdMap.get(event.PJN_Patient__c);
                idList.add(event.Id);
                accountToEventIdMap.put(event.PJN_Patient__c, idList);
            } else {
                accountToEventIdMap.put(event.PJN_Patient__c, new List<Id>{event.Id});
            }

        }

        Map<Id, Account> result = new Map<Id, Account>();

        for (Account acct : [SELECT FirstName, LastName FROM Account WHERE Id IN :accountIds]) {
            for (Id currentId : accountToEventIdMap.get(acct.Id)) {
                result.put(currentId, acct);
            }
        }

        return result;
    }

    private Map<Id, String> buildIdToNetworkIdMap() {
        Set<Id> accountIds = new Set<Id>();

        for (PJN_Event__c event : eventMap.values()) {
            accountIds.add(event.PJN_New_Physician__c);
            accountIds.add(event.PJN_Previous_Physician__c);
            accountIds.add(event.PJN_Physician_Network_Id__c);
        }

        Map<Id, String> accountIdToVeevaNetworkId = new Map<Id, String>();

        for (Account acct : [SELECT PJN_NPI__c FROM Account WHERE Id IN :accountIds]) {
            accountIdToVeevaNetworkId.put(acct.Id, acct.PJN_NPI__c);
        }

        return accountIdToVeevaNetworkId;
    }


    private List<Object> addParents(List<Object> objects, Map<Id, String> caseExternalIds) {
        List<Object> results = new List<Object>();
        for (Object obj : objects) {
            Map<String, Object> objMap = (Map<String, Object>) obj;
            PJN_Event__c event = eventMap.get((String) objMap.get('PJN_External_ID_c'));
            objMap.put('PJN_Enrollment_c', caseExternalIds.get(event.PJN_Case__c));
            results.add((Object) objMap);
        }
        return results;
    }

    private List<Object> convertToObjects(List<PJN_VeevaCRMEnrollment> enrollments) {
        String serializedEnrollments = JSON.serialize(enrollments);
        return (List<Object>) JSON.deserializeUntyped(serializedEnrollments);
    }

    private List<Object> convertToObjects(List<PJN_VeevaCRMStatus> statuses) {
        String serializedStatuses = JSON.serialize(statuses);
        return (List<Object>) JSON.deserializeUntyped(serializedStatuses);
    }

    /**
     * Extract and return an error result from an Insert Result returned from Veeva CRM.
     * @param mappedInsertResult
     * @returns `String`
     */
    private String getErrorStringFromInsertResult(Map<String, Object> mappedInsertResult) {
        String result = '';
        List<Object> errors = (List<Object>) mappedInsertResult.get('errors');
        for (Object error : errors) {
            Map<String, Object> errorMap = (Map<String, Object>) error;
            result += ((String) errorMap.get('statusCode')) + ': ' + ((String) errorMap.get('message')).normalizeSpace() + '.\n';
        }
        return result;
    }

    private Map<Id, String> getExistingExternalIds() {
        Set<Id> caseIds = new Set<Id>();
        for (PJN_Event__c event : eventMap.values()) {
            caseIds.add(event.PJN_Case__c);
        }

        Map<Id, String> result = new Map<Id, String>();
        for (Case c : [SELECT PJN_Veeva_CRM_Enrollment_External_Id__c FROM Case]) {
            if (c.PJN_Veeva_CRM_Enrollment_External_Id__c != NULL) {
                result.put(c.Id, c.PJN_Veeva_CRM_Enrollment_External_Id__c);
            }
        }

        return result;
    }

    /**
     * Dynamically create the SObject that will be updated with Veeva CRM integration results.
     * @param mappedInsertResult
     * @returns `SObject`
     */
    private SObject instantiateSObject(Map<String, Object> mappedInsertResult) {
        SObject obj;
        // if record is an event
        if (eventMap.containsKey((String) mappedInsertResult.get('referenceId'))) {
            obj = Schema.getGlobalDescribe().get('PJN_Event__c').newSObject();
            obj.put('PJN_Date_Sent_to_Veeva_CRM__c', Datetime.now());
        // else it's a case
        } else {
            obj = Schema.getGlobalDescribe().get('Case').newSObject();
        }

        return obj;
    }

    /**
     * The Events were received by Veeva CRM and the response is valid, this method parses the deserialized response.
     * @param deserializedResponse
     * @returns `List<SObject>`
     */
    private List<SObject> parseValidResults(Map<String, Object> deserializedResponse) {
        List<SObject> results = new List<SObject>();
        List<Object> insertResults = (List<Object>) deserializedResponse.get('results');

        for(Object insertResult : insertResults) {
            Map<String, Object> mappedInsertResult = (Map<String, Object>) insertResult;
            if (PJN_VeevaCRMConnectionUtility.resultHasId(mappedInsertResult)) {
                results.add(processInsertResult(mappedInsertResult));
            }
        }

        return results;
    }

    /**
     * Process individual result return from Veeva CRM.
     * @param mappedInsertResult
     * @returns `SObject`
     */
    private SObject processInsertResult(Map<String, Object> mappedInsertResult) {

        SObject obj = instantiateSObject(mappedInsertResult);

        // set universal fields
        obj.put('Id', (String) mappedInsertResult.get('referenceId'));

        // set remaining fields based on if an error occurred
        if (mappedInsertResult.containsKey('errors')) {
            obj.put('PJN_Veeva_CRM_Enrollment_Error__c', getErrorStringFromInsertResult(mappedInsertResult));
            obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Enrollment Sent Failed');
        } else {
            // no error occurred, add External Id from Veeva CRM.
            obj.put('PJN_Veeva_CRM_Enrollment_External_Id__c', (String) mappedInsertResult.get('id'));
            obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Enrollment Sent');
        }

        return obj;
    }

    /**
     * Parse a composite tree response.
     * @param remoteVeevaOrgResponse
     * @returns `List<SObject>`
     */
    private List<SObject> responseParser(HttpResponse remoteVeevaOrgResponse) {
        List<SObject> results = new List<SObject>();

        if(remoteVeevaOrgResponse != null) {
            Map<String, Object> deserializedResponse = PJN_VeevaCRMConnectionUtility.deserializeJson(remoteVeevaOrgResponse.getBody());
            if (!deserializedResponse.isEmpty()){
                results.addAll(parseValidResults(deserializedResponse));
            }
        }

        return results;
    }
}