/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake Email Search
 */
public with sharing class MVN_DataLakeCMSearchEmail {

    /**
     * Search Email Wrapper
     */
    public static MVN_DataLakeCMEmail searchEmail;

    /**
     * Get Email Search query to filter account results in the search
     * using isPersonSearch parameter to allow HCP Email only
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @return  `String`
     */
    public static String getAccountFilter(Boolean isPersonSearch) {
        String emailFilterQuery = '';
        if (!isPersonSearch) {
            return emailFilterQuery;
        }
        String emailFilters = searchEmail != null ? searchEmail.getSearchFilters() : null;
        if (String.isNotBlank(emailFilters)) {
            emailFilterQuery += '(hcp_id in ' +
                '(SELECT hcp_email_hcp_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hcp_email WHERE ' + emailFilters + ')' +
                ') OR ';
        }
        return emailFilterQuery;
    }

    /**
     * Defines the Customer master search query using isPersonSearch to define Email type
     * and accountIds to retrieve the related emails only
     * This Search for HCP or HCO email depending on isPersonSearch
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMEmail>>`
     */
    public static Map<String, List<MVN_DataLakeCMEmail>> searchEmails(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMEmail>> emailsMap = new Map<String, List<MVN_DataLakeCMEmail>>();
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<String, List<MVN_DataLakeCMEmail>>();
        }
        String cmSearchQuery = getEmailSearchQuery(isPersonSearch, accountIds);
        String emailIdFieldName = isPersonSearch ? 'hcp_email_id' : 'hco_email_id';
        String parentIdFieldName = isPersonSearch ? 'hcp_email_hcp_id' : 'hco_email_hco_id';
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey(emailIdFieldName) && dtRecord.containsKey(parentIdFieldName)) {
                        String parentId = String.valueOf(dtRecord.get(parentIdFieldName));
                        List<MVN_DataLakeCMEmail> dataLakeEmails = emailsMap.containsKey(parentId) ?
                            emailsMap.get(parentId) :
                            new List<MVN_DataLakeCMEmail>();
                        String dlEmailJSON = System.JSON.serialize(dtRecord);
                        dataLakeEmails.add((MVN_DataLakeCMEmail) System.JSON.deserialize(dlEmailJSON, MVN_DataLakeCMEmail.class));
                        emailsMap.put(parentId, dataLakeEmails);
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
        return emailsMap;
    }

    /**
     * Get Email Search Query using isPersonSearch to define HCP or HCO type
     * and account ids to get only related Emails
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `String`
     */
    private static String getEmailSearchQuery(Boolean isPersonSearch, Set<String> accountIds) {
        String dbName = isPersonSearch ? 'data_semarchy_cm_pub_x_hcp_email' : 'data_semarchy_cm_pub_x_hco_email';
        String filterName = isPersonSearch ? 'hcp_email_hcp_id' : 'hco_email_hco_id';
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + dbName + ' WHERE ' + filterName + ' in (';
        for (String accountId : accountIds) {
            query += '' + accountId + ',';
        }
        String statusFieldName = isPersonSearch ? 'hcp_email_valid_status' : 'hco_email_valid_status';
        return query.substringBeforeLast(',') + ') AND ' + statusFieldName + ' = \'Y\'';
    }
}