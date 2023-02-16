/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake HCP to HCO Affiliation Search
 */
public with sharing class MVN_DataLakeCMSearchAffiliation {

    /**
     * Defines the Customer master search query using isPersonSearch to define Affiliation parent
     * and accountIds to retrieve the related affiliations only
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMAffiliation>>`
     */
    public static Map<String, List<MVN_DataLakeCMAffiliation>> searchAffiliations(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMAffiliation>> affiliationsByParentId = new Map<String, List<MVN_DataLakeCMAffiliation>>();
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<String, List<MVN_DataLakeCMAffiliation>>();
        }
        String cmSearchQuery = getAffiliationSearchQuery(isPersonSearch, accountIds);
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('hco_hcp_affiliation_id') && dtRecord.containsKey('hco_hcp_affiliation_hcp_id') && dtRecord.containsKey('hco_hcp_affiliation_hco_id')) {
                        String parentField = isPersonSearch ? 'hco_hcp_affiliation_hcp_id' : 'hco_hcp_affiliation_hco_id';
                        String parentId = String.valueOf(dtRecord.get(parentField));
                        List<MVN_DataLakeCMAffiliation> dataLakeAffiliations = affiliationsByParentId.containsKey(parentId) ?
                            affiliationsByParentId.get(parentId) :
                            new List<MVN_DataLakeCMAffiliation>();
                        String dlAffiliationJSON = System.JSON.serialize(dtRecord);
                        dataLakeAffiliations.add((MVN_DataLakeCMAffiliation) System.JSON.deserialize(dlAffiliationJSON, MVN_DataLakeCMAffiliation.class));
                        affiliationsByParentId.put(parentId, dataLakeAffiliations);
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
        return affiliationsByParentId;
    }

    /**
     * Get HCP to HCO Affiliation Search query
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account IDs
     * @return  `String`
     */
    public static String getAffiliationSearchQuery(Boolean isPersonSearch, Set<String> accountIds) {
        String filterName = isPersonSearch ? 'hco_hcp_affiliation_hcp_id' : 'hco_hcp_affiliation_hco_id';
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hco_hcp_affiliation WHERE ' + filterName + ' in (';
        for (String accountId : accountIds) {
            query += '' + accountId + ',';
        }
        return query.substringBeforeLast(',') + ') AND hco_hcp_affiliation_status = \'Y\'';
    }
}