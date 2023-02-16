public with sharing class PJN_VeevaCRMSuggestionConnector implements PJN_ICaseToCRMConnector {

    PJN_CRM_Connection_Setting__mdt connectionSetting;
    Map<Id, Case> caseMap;

    public PJN_VeevaCRMSuggestionConnector() {}  // NOPMD - no arg constructor for dynamically calling

    /**
     * Prepare a json string to pass to Veeva CRM integration.
     * @param wrapper
     * @returns `String`
     */
    public String mapCases(PJN_CaseToCRMHdlr.ConnectionWrapper wrapper) {
        connectionSetting = wrapper.connectionSetting;
        caseMap = wrapper.caseMap;

        Set<Id> physicianIdSet = new Set<Id>();
        for (Case currentCase : caseMap.values()) {
            physicianIdSet.add(currentCase.PJN_Physician_Id__c);
        }

        Map<Id, String> accountIdToNetworkIdMap = queryAccountIdToNetworkIdMap(physicianIdSet);
        HTTPResponse remoteVeevaOrgQueryResponse = PJN_VeevaCRMConnectionUtility.calloutRemoteCrm('GET', 'callout:' + connectionSetting.PJN_Named_Credential__c + '/services/data/v49.0/query/?q=SELECT+Id+%2C+NPI_vod__c+FROM+Account+WHERE+NPI_vod__c+IN+%28' + PJN_VeevaCRMConnectionUtility.urlEncodedStringList(accountIdToNetworkIdMap.values()) + '%29');
        Map<Id, Id> accountIdToVeevaAccountId = buildAccountIdToVeevaAccountId(accountIdToNetworkIdMap, parseQueryResponse(remoteVeevaOrgQueryResponse));
        List<PJN_VeevaCRMSuggestion> suggestions = new List<PJN_VeevaCRMSuggestion>();

        for (Case currentCase : caseMap.values()) {
            if (accountIdToNetworkIdMap.containsKey(currentCase.PJN_Physician_Id__c) && accountIdToNetworkIdMap.get(currentCase.PJN_Physician_Id__c) != NULL) {
                suggestions.add(new PJN_VeevaCRMSuggestion(currentCase, accountIdToVeevaAccountId));
            }
        }

        if (suggestions.size() > 0) {
            String result = PJN_VeevaCRMConnectionUtility.createJsonString(convertToObjects(suggestions));
            System.debug('jsonBody returned by mapCases: ' + result);
            return result;
        }

        return null;
    }

    public List<Case> sendToCRM(String jsonEnrollmentStatus) {
        try {
            List<SObject> results = new List<SObject>();
            HTTPResponse remoteVeevaOrgResponse = PJN_VeevaCRMConnectionUtility.calloutRemoteCrm('POST', 'callout:' + connectionSetting.PJN_Named_Credential__c + '/services/data/v49.0/composite/tree/Suggestion_vod__c/', jsonEnrollmentStatus);
            results.addAll(compositeResponseParser(remoteVeevaOrgResponse));
            return (List<Case>) results;
        } catch (Exception e) {
            System.debug(e);
        }

        return new List<Case>();
    }

    private Map<Id, Id> buildAccountIdToVeevaAccountId(Map<Id, String> accountIdToNetworkIdMap, Map<String, Id> networkToVeevaId) {
        Map<Id, Id> result = new  Map<Id, Id>();

        for (Id accountId : accountIdToNetworkIdMap.keySet()) {
            if (networkToVeevaId.containsKey(accountIdToNetworkIdMap.get(accountId))) {
                result.put(accountId, networkToVeevaId.get(accountIdToNetworkIdMap.get(accountId)));
            }
        }

        return result;
    }

    /**
     * Parse a composite tree response.
     * @param remoteVeevaOrgResponse
     * @returns `List<SObject>`
     */
    private List<SObject> compositeResponseParser(HttpResponse remoteVeevaOrgResponse) {
        List<SObject> results = new List<SObject>();

        if(remoteVeevaOrgResponse != null) {
            Map<String, Object> deserializedResponse = PJN_VeevaCRMConnectionUtility.deserializeJson(remoteVeevaOrgResponse.getBody());
            if (!deserializedResponse.isEmpty()){
                results.addAll(parseValidResults(deserializedResponse));
            }
        }

        return results;
    }

    private List<Object> convertToObjects(List<PJN_VeevaCRMSuggestion> suggestions) {
        String serializedSuggestions = JSON.serialize(suggestions);
        return (List<Object>) JSON.deserializeUntyped(serializedSuggestions);
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

    private Map<String, String> parseDeserializedQueryResponse(Map<String, Object> deserializedResponse) {
        Map<String, String> result = new Map<String, String>();
        List<Object> records = (List<Object>) deserializedResponse.get('records');

        for (Object record : records) {
            Map<String, Object> mappedRecord = (Map<String, Object>) record;

            result.put((String) mappedRecord.get('NPI_vod__c'), (Id) mappedRecord.get('Id'));
        }

        return result;
    }

    private Map<String, String> parseQueryResponse(HttpResponse response) {
        Map<String, String> result = new Map<String, String>();

        if(response != null) {
            Map<String, Object> deserializedResponse = PJN_VeevaCRMConnectionUtility.deserializeJson(response.getBody());
            if (!deserializedResponse.isEmpty()){
                result = parseDeserializedQueryResponse(deserializedResponse);
            }
        }

        return result;
    }

    /**
     * The Cases were received by Veeva CRM and the response is valid, this method parses the deserialized response.
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

        SObject obj = Schema.getGlobalDescribe().get('Case').newSObject();

        // set universal fields
        obj.put('Id', (String) mappedInsertResult.get('referenceId'));

        obj.put('PJN_Date_Suggestion_Sent_to_Veeva_CRM__c', Datetime.now());

        // set remaining fields based on if an error occurred
        if (mappedInsertResult.containsKey('errors')) {
            obj.put('PJN_Veeva_CRM_Suggestion_Error__c', getErrorStringFromInsertResult(mappedInsertResult));
            obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Suggestion Sent Failed');
        } else {
            // no error occurred, add External Id from Veeva CRM.
            obj.put('PJN_Veeva_CRM_Suggestion_External_Id__c', (String) mappedInsertResult.get('id'));
            obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Suggestion Sent');
        }

        return obj;
    }

    private Map<Id, String> queryAccountIdToNetworkIdMap(Set<Id> accountIds) {
        Map<Id, String> accountIdToNetworkIdMap = new Map<Id, String>();
        for (Account acct : [SELECT PJN_NPI__c FROM Account WHERE Id IN :accountIds]) {
            if (acct.PJN_NPI__c != NULL) {
                accountIdToNetworkIdMap.put(acct.Id, acct.PJN_NPI__c);
            }
        }
        return accountIdToNetworkIdMap;
    }
}