/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake License Search
 */
public with sharing class MVN_DataLakeCMSearchLicense {

    /**
     * Defines the Customer master search query using isPersonSearch to define search type
     * and accountIds to retrieve the related licenses only
     * This Search for HCP licenses only
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMEmail>>`
     */
    public static Map<String, List<MVN_DataLakeCMLicense>> searchLicenses(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMLicense>> hcpLicenses = new Map<String, List<MVN_DataLakeCMLicense>>();
        if (accountIds == null || accountIds.isEmpty() || !isPersonSearch) {
            return new Map<String, List<MVN_DataLakeCMLicense>>();
        }
        String cmSearchQuery = getLicenseSearchQuery(accountIds);
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('hcp_license_id') && dtRecord.containsKey('hcp_license_hcp_id')) {
                        String hcpId = String.valueOf(dtRecord.get('hcp_license_hcp_id'));
                        List<MVN_DataLakeCMLicense> dataLakeLicenses = hcpLicenses.containsKey(hcpId) ?
                            hcpLicenses.get(hcpId) :
                            new List<MVN_DataLakeCMLicense>();
                        String dlLicenseJSON = System.JSON.serialize(dtRecord);
                        dataLakeLicenses.add((MVN_DataLakeCMLicense) System.JSON.deserialize(dlLicenseJSON, MVN_DataLakeCMLicense.class));
                        hcpLicenses.put(hcpId, dataLakeLicenses);
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
        return hcpLicenses;
    }

    /**
     * Get License Search Query using account ids to get only related Licenses
     * @param accountIds    DataLake Account Ids
     * @return  `String`
     */
    public static String getLicenseSearchQuery(Set<String> accountIds) {
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hcp_license WHERE hcp_license_hcp_id in (';
        for (String accountId : accountIds) {
            query += '' + accountId + ',';
        }
        return query.substringBeforeLast(',') + ') AND hcp_license_status = \'ACTIVE\'';
    }
}