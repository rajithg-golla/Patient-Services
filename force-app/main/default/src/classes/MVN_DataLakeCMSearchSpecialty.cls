/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake Specialty Search
 */
public with sharing class MVN_DataLakeCMSearchSpecialty {

    /**
     * Defines the Customer master search query using isPersonSearch to define search type
     * and accountIds to retrieve the related specialties only
     * This Search for HCP Specialty only
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMEmail>>`
     */
    public static Map<String, List<MVN_DataLakeCMSpecialty>> searchSpecialties(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMSpecialty>> hcpSpecialties = new Map<String, List<MVN_DataLakeCMSpecialty>>();
        if (accountIds == null || accountIds.isEmpty() || !isPersonSearch) {
            return new Map<String, List<MVN_DataLakeCMSpecialty>>();
        }
        String cmSearchQuery = getSpecialtySearchQuery(accountIds);
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('hcp_spec_id') && dtRecord.containsKey('hcp_spec_hcp_id')) {
                        String hcpId = String.valueOf(dtRecord.get('hcp_spec_hcp_id'));
                        List<MVN_DataLakeCMSpecialty> dataLakeSpecialties = hcpSpecialties.containsKey(hcpId) ?
                            hcpSpecialties.get(hcpId) :
                            new List<MVN_DataLakeCMSpecialty>();
                        String dlSpecialtyJSON = System.JSON.serialize(dtRecord);
                        dataLakeSpecialties.add((MVN_DataLakeCMSpecialty) System.JSON.deserialize(dlSpecialtyJSON, MVN_DataLakeCMSpecialty.class));
                        hcpSpecialties.put(hcpId, dataLakeSpecialties);
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
        return hcpSpecialties;
    }

    /**
     * Get Specialty Search Query using account ids to get only related Specialties
     * @param accountIds    DataLake Account Ids
     * @return  `String`
     */
    public static String getSpecialtySearchQuery(Set<String> accountIds) {
        String query = 'SELECT * FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hcp_specialty WHERE hcp_spec_hcp_id in (';
        for (String accountId : accountIds) {
            query += '' + accountId + ',';
        }
        return query.substringBeforeLast(',') + ') AND hcp_spec_valid_status = \'Y\'';
    }
}