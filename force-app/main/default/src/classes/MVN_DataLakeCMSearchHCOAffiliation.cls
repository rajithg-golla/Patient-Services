/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake HCO to HCO Affiliation Search
 */
public with sharing class MVN_DataLakeCMSearchHCOAffiliation {

    /**
     * Defines the Customer master search query using isPersonSearch to allow HCO search only
     * and accountIds to retrieve the related HCO To HCO Affiliations only
     * @param isPersonSearch    Defines if HCP or HCP Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMHCOAffiliation>>`
     */
    public static Map<String, List<MVN_DataLakeCMHCOAffiliation>> searchHCOAffiliations(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMHCOAffiliation>> hcoAffiliationByAccId = new Map<String, List<MVN_DataLakeCMHCOAffiliation>>();
        if (accountIds == null || accountIds.isEmpty() || isPersonSearch) {
            return new Map<String, List<MVN_DataLakeCMHCOAffiliation>>();
        }
        String cmSearchQuery = getHCOAffiliationSearchQuery(accountIds);
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('hco_hco_affiliation_id') && dtRecord.containsKey('hco_hco_affiliation_hco_id_parent') && dtRecord.containsKey('hco_hco_affiliation_hco_id_child')) {
                        String parentId = String.valueOf(dtRecord.get('hco_hco_affiliation_hco_id_parent'));
                        List<MVN_DataLakeCMHCOAffiliation> dataLakeAffiliations = hcoAffiliationByAccId.containsKey(parentId) ?
                            hcoAffiliationByAccId.get(parentId) :
                            new List<MVN_DataLakeCMHCOAffiliation>();
                        String dlAffiliationJSON = System.JSON.serialize(dtRecord);
                        MVN_DataLakeCMHCOAffiliation hcoHcoAffiliation = (MVN_DataLakeCMHCOAffiliation) System.JSON.deserialize(dlAffiliationJSON, MVN_DataLakeCMHCOAffiliation.class);
                        dataLakeAffiliations.add(hcoHcoAffiliation);
                        hcoAffiliationByAccId.put(parentId, dataLakeAffiliations);
                        String childId = String.valueOf(dtRecord.get('hco_hco_affiliation_hco_id_child'));
                        dataLakeAffiliations = hcoAffiliationByAccId.containsKey(childId) ?
                            hcoAffiliationByAccId.get(childId) :
                            new List<MVN_DataLakeCMHCOAffiliation>();
                        dataLakeAffiliations.add(hcoHcoAffiliation);
                        hcoAffiliationByAccId.put(childId, dataLakeAffiliations);
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
        return hcoAffiliationByAccId;
    }

    /**
     * Get HCO to HCO Affiliation Search Query using account ids to filter
     * @param accountIds    DataLake Account Ids
     * @return  `String`
     */
    public static String getHCOAffiliationSearchQuery(Set<String> accountIds) {
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hco_hco_affiliation WHERE ';
        String accountIdsAsString = '(';
        for (String accountId : accountIds) {
            accountIdsAsString += '' + accountId + ',';
        }
        accountIdsAsString = accountIdsAsString.substringBeforeLast(',') + ')';
        query += '(hco_hco_affiliation_hco_id_parent in ' + accountIdsAsString + ' OR hco_hco_affiliation_hco_id_child in ' + accountIdsAsString + ')';
        return query + ' AND hco_hco_affiliation_status = \'Y\'';
    }
}