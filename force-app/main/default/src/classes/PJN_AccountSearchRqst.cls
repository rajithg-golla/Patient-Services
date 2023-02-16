/**
 * @author      Mavens
 * @group       AccountSearch
 * @description define an account search request to be sent to any search handlers
 */
public class PJN_AccountSearchRqst {
    @AuraEnabled public Account account;
    @AuraEnabled public List<String> accountRecordTypeNames; //the record type developer names to query
    @AuraEnabled public PJN_Contact_Information__c contactInfo;
    @AuraEnabled public Boolean isPersonSearch;
    @AuraEnabled public Integer maxResults;

    public Map<String, Map<String, Object>> populatedInfoByObject {
        get {
            if (populatedInfoByObject == null) {
                populatedInfoByObject = new Map<String, Map<String, Object>>();
                populatedInfoByObject.put(
                    'Account',
                    getNonNulls(account.getPopulatedFieldsAsMap())
                );
                populatedInfoByObject.put(
                    'PJN_Contact_Information__c',
                    getNonNulls(contactInfo.getPopulatedFieldsAsMap())
                );
            }
            return populatedInfoByObject;
        }
        set;
    }

    private static Map<String, Object> getNonNulls(Map<String, Object> populatedFields) {
        Map<String, Object> nonNulls = new Map<String, Object>();

        for (String field : populatedFields.keySet()) {
            if (populatedFields.get(field) != null) {
                //TODO: Determine if this test is valid across all types
                if (String.isNotBlank(String.valueOf(populatedFields.get(field)))) {
                    nonNulls.put(field, populatedFields.get(field));
                }
            }
        }
        return nonNulls;
    }
}