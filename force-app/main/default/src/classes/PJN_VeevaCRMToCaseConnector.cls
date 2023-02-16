/**
 * Network Case Sync controller
 * @author  Mavens
 */
public with sharing class PJN_VeevaCRMToCaseConnector implements PJN_ICRMToCaseConnector {

    public Boolean syncEscalatedCases(PJN_CRM_Connection_Setting__mdt connectionSetting, Id recordId) {
        Map<String, Id> suggestionIdMap = getSuggestionIds(recordId);
        String result = '(';
        for (String currentString : (new List<String>(suggestionIdMap.keySet()))) {
            result += '\'' + currentString + '\',';
        }
        result = result.removeEnd(',');
        result += ')';
        String query = EncodingUtil.urlEncode('SELECT Id,Dismissed_vod__c,Marked_As_Complete_vod__c FROM Suggestion_vod__c WHERE Id IN ' + result, 'UTF-8');
    	HTTPResponse remoteVeevaOrgQueryResponse = PJN_VeevaCRMConnectionUtility.calloutRemoteCrm('GET', 'callout:' + connectionSetting.PJN_Named_Credential__c + '/services/data/v49.0/query/?q=' + query);
        List<SObject> objects = parseQueryResponse(connectionSetting, remoteVeevaOrgQueryResponse, suggestionIdMap);
        update objects; // NOPMD - no check necessary
        System.debug('objects: ' + objects);

        return true;
    }

    private  Map<String, Id> getSuggestionIds(Id recordId) {

        Map<String, Id> suggestionIdMap = new Map<String, Id>();

        for (Case record : [SELECT PJN_Veeva_CRM_Suggestion_External_Id__c FROM Case WHERE Id = :recordId OR ParentId = :recordId OR PJN_Enrollment_Activity__c = :recordId]) {
            if (!String.isBlank(record.PJN_Veeva_CRM_Suggestion_External_Id__c)) {
                suggestionIdMap.put(record.PJN_Veeva_CRM_Suggestion_External_Id__c, record.Id);
            }
        }

        return suggestionIdMap;
    }

    private List<SObject> parseDeserializedQueryResponse(PJN_CRM_Connection_Setting__mdt connectionSetting, Map<String, Object> deserializedResponse, Map<String, Id> suggestionIdMap) {
        List<SObject> result = new List<SObject>();
        List<Object> records = (List<Object>) deserializedResponse.get('records');

        for (Object record : records) {
            Map<String, Object> mappedRecord = (Map<String, Object>) record;

            System.debug('mappedRecord: ' + mappedRecord);
            System.debug('suggestionIdMap: ' + suggestionIdMap);

            // prevent it from creating a record to update if there is nothing to update
            if (hasUpdateInformation(suggestionIdMap, mappedRecord)) {

                SObject obj = Schema.getGlobalDescribe().get('Case').newSObject();
                obj.put('Id', suggestionIdMap.get((String) mappedRecord.get('Id')));

                if (hasIntegerAboveZero(mappedRecord, 'Marked_As_Complete_vod__c')) {
                    obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Complete');
                    obj.put('Status', connectionSetting.PJN_Case_Sync_Complete_Status__c);
                }

                if (hasIntegerAboveZero(mappedRecord, 'Dismissed_vod__c')) {
                    obj.put('PJN_Veeva_CRM_Suggestion_Status__c', 'Dismissed');
                    obj.put('Status', connectionSetting.PJN_Case_Sync_Dismissed_Status__c);
                }

                result.add(obj);
            }
        }

        return result;
    }

    private Boolean hasUpdateInformation(Map<String, Id> suggestionIdMap, Map<String, Object> mappedRecord) {
        return mappedRecord.containsKey('Id') &&
               suggestionIdMap.containsKey((String) mappedRecord.get('Id')) &&
               (hasIntegerAboveZero(mappedRecord, 'Marked_As_Complete_vod__c') || hasIntegerAboveZero(mappedRecord, 'Dismissed_vod__c'));
    }

    private Boolean hasIntegerAboveZero(Map<String, Object> mappedRecord, String fieldName) {
        return mappedRecord.containsKey(fieldName) && mappedRecord.get(fieldName) != NULL && (Decimal) mappedRecord.get(fieldName) > 0;
    }

    private List<SObject> parseQueryResponse(PJN_CRM_Connection_Setting__mdt connectionSetting, HttpResponse response, Map<String, Id> suggestionIdMap) {
        List<SObject> result = new List<SObject>();

        if(response != null) {
            Map<String, Object> deserializedResponse = PJN_VeevaCRMConnectionUtility.deserializeJson(response.getBody());
            if (!deserializedResponse.isEmpty()){
                result = parseDeserializedQueryResponse(connectionSetting, deserializedResponse, suggestionIdMap);
            }
        }

        return result;
    }
}