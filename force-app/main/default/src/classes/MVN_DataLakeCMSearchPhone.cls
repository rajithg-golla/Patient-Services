/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake Phone Search
 */
public with sharing class MVN_DataLakeCMSearchPhone {

    /**
     * Defines the Customer master search query using isPersonSearch to define Phone type
     * and accountIds to retrieve the related phones only
     * This Search for HCP or HCO phone depending on isPersonSearch
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMEmail>>`
     */
    public static Map<String, List<MVN_DataLakeCMPhone>> searchPhones(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMPhone>> hcpPhones = new Map<String, List<MVN_DataLakeCMPhone>>();
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<String, List<MVN_DataLakeCMPhone>>();
        }
        String cmSearchQuery = getPhoneSearchQuery(isPersonSearch, accountIds);
        String phoneIdFieldName = isPersonSearch ? 'hcp_phone_id' : 'hco_phone_id';
        String parentIdFieldName = isPersonSearch ? 'hcp_phone_hcp_id' : 'hco_phone_hco_id';
        String typeCodeFieldName = isPersonSearch ? 'hcp_phone_type_cd' : 'hco_phone_type_cd';
        String numberFieldName = isPersonSearch ? 'hcp_phone_standard_phone_num' : 'hco_phone_standard_phone_num';
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    Boolean isValidPhoneOrFax = dtRecord.containsKey(phoneIdFieldName)
                        && dtRecord.containsKey(parentIdFieldName)
                        && dtRecord.containsKey(typeCodeFieldName)
                        && dtRecord.containsKey(numberFieldName)
                        && String.isNotBlank(String.valueOf(dtRecord.get(numberFieldName)));
                    if (isValidPhoneOrFax) {
                        String parentId = String.valueOf(dtRecord.get(parentIdFieldName));
                        List<MVN_DataLakeCMPhone> dataLakePhones = hcpPhones.containsKey(parentId) ?
                            hcpPhones.get(parentId) :
                            new List<MVN_DataLakeCMPhone>();
                        String dlPhoneJSON = System.JSON.serialize(dtRecord);
                        dataLakePhones.add((MVN_DataLakeCMPhone) System.JSON.deserialize(dlPhoneJSON, MVN_DataLakeCMPhone.class));
                        hcpPhones.put(parentId, dataLakePhones);
                    }
                }
            }
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, System.JSON.serializePretty(datalakeResponse));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch (Exception ex) {
            System.debug('### DataLake::CM::Search::Error: ' + ex.getStackTraceString());
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, ex.getMessage());
            PJN_PublishTransactionLog.addError(transactionLog);
        }
        return hcpPhones;
    }

    /**
     * Get Phone Search Query using isPersonSearch to define HCP or HCO type
     * and account ids to get only related Phones
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `String`
     */
    public static String getPhoneSearchQuery(Boolean isPersonSearch, Set<String> accountIds) {
        String dbName = isPersonSearch ? 'data_semarchy_cm_pub_x_hcp_phone' : 'data_semarchy_cm_pub_x_hco_phone';
        String filterName = isPersonSearch ? 'hcp_phone_hcp_id' : 'hco_phone_hco_id';
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + dbName + ' WHERE ' + filterName + ' in (';
        for (String accountId : accountIds) {
            query += '' + accountId + ',';
        }
        String statusFieldName = isPersonSearch ? 'hcp_phone_valid_status' : 'hco_phone_valid_status';
        return query.substringBeforeLast(',') + ') AND ' + statusFieldName + ' = \'Y\'';
    }
}