/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake Account Search
 */
public with sharing class MVN_DataLakeCMSearchAccount {

    /**
     * HCP Account Search Wrapper
     */
    public static MVN_DataLakeCMHCP searchHCP;

    /**
     * HCO Account Search Wrapper
     */
    public static MVN_DataLakeCMHCO searchHCO;

    /**
     * Get Account Search query using isPersonSearch parameter to define HCP or HCO for the Account
     * @param isPersonSearch    Defines if Person or Business search
     * @return  `String`
     */
    public static String getAccountSearchQuery(Boolean isPersonSearch) {
        String query = 'SELECT * from ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT;
        query += isPersonSearch ? 'data_semarchy_cm_pub_m_hcp_profile' : 'data_semarchy_cm_pub_m_hco_profile';

        String whereStatements = isPersonSearch ? searchHCP.getSearchFilters() : searchHCO.getSearchFilters();
        whereStatements = String.isNotBlank(whereStatements) ?
            ' WHERE ' + whereStatements :
            '';

        return query + whereStatements;
    }

    /**
     * Defined the Customer master search query, call DataLake to obtain the accounts
     * @param cmSearchQuery     Customer Master Search Query
     * @return  `List<Object>`
     */
    public static List<Object> searchAccounts(String cmSearchQuery) {
        List<Object> dataLakeAccounts = new List<Object>();
        if (String.isBlank(cmSearchQuery)) {
            return dataLakeAccounts;
        }
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                dataLakeAccounts = (List<Object>) datalakeResponse.get('Items');
            }
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, System.JSON.serializePretty(datalakeResponse));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch (Exception ex) {
            System.debug('### DataLake::CM::Search::Error: ' + ex.getStackTraceString());
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(cmSearchQuery, ex.getMessage());
            PJN_PublishTransactionLog.addError(transactionLog);
        }
        return dataLakeAccounts;
    }

    /**
     * Get all account ids from the DataLake Account results using isPerson Search parameter
     * to define if get HCP or HCO Id
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param datalakeAccounts  DataLake Account results
     * @return  `Set<String>`
     */
    public static Set<String> getAccountIds(Boolean isPersonSearch, List<Object> datalakeAccounts) {
        Set<String> accountIds = new Set<String>();
        String accountIdFieldName = isPersonSearch ? 'hcp_id' : 'hco_id';
        for (Object dataLakeAccount : datalakeAccounts) {
            Map<String, Object> dataLakeAccountMap = (Map<String, Object>) dataLakeAccount;
            accountIds.add(String.valueOf(dataLakeAccountMap.get(accountIdFieldName)));
        }
        return accountIds;
    }
}