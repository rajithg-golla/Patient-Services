/**
 * @author      Mavens
 * @group       DataLake
 * @description Handles DataLake Address Search
 */
public with sharing class MVN_DataLakeCMSearchAddress {

    /**
     * Search Address Wrapper
     */
    public static MVN_DataLakeCMAddress searchAddress;

    /**
     * Get Address Search query to filter account results in the search
     * using isPersonSearch parameter to define HCP or HCO Address
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @return  `String`
     */
    public static String getAccountFilter(Boolean isPersonSearch) {
        String addressFilterQuery = '';
        String addressFilters = searchAddress != null ? searchAddress.getSearchFilters() : null;
        if (isPersonSearch && String.isNotBlank(addressFilters)) {
            addressFilterQuery += '(hcp_id in ' +
                '(SELECT hcp_location_hcp_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hcp_location WHERE hcp_location_loc_id in ' +
                '(SELECT hco_cm_location_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_location WHERE hco_location_addr_id in ' +
                '(SELECT addr_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_address WHERE ' + addressFilters + ')))' +
                ') OR ';
        } else if (!isPersonSearch && String.isNotBlank(addressFilters)) {
            addressFilterQuery += '(hco_id in ' +
                '(SELECT hco_location_hco_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_location WHERE hco_location_addr_id in ' +
                '(SELECT addr_id FROM ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_address WHERE ' + addressFilters + '))' +
                ') OR ';
        }
        return addressFilterQuery;
    }

    /**
     * Defines the Customer master search query using isPersonSearch to define Address type
     * and accountIds to retrieve the related addresses only
     * @param isPersonSearch    Defines if HCP or HCO Search
     * @param accountIds        DataLake Account Ids
     * @return  `Map<String, List<MVN_DataLakeCMAddress>>`
     */
    public static Map<String, List<MVN_DataLakeCMAddress>> searchAddresses(Boolean isPersonSearch, Set<String> accountIds) {
        Map<String, List<MVN_DataLakeCMAddress>> addressesMap = new Map<String, List<MVN_DataLakeCMAddress>>();
        if (accountIds == null || accountIds.isEmpty()) {
            return addressesMap;
        }
        String cmSearchQuery = isPersonSearch ?
            getHCPAddressSearchQuery(accountIds) :
            getHCOAddressSearchQuery(accountIds);
        try {
            HttpRequest request = MVN_DataLakeCMSearchUtil.getDataLakeRequest(cmSearchQuery);
            Map<String, Object> datalakeResponse = MVN_DataLakeCMSearchUtil.callDataLake(request);
            if (datalakeResponse != null && datalakeResponse.containsKey('Items')) {
                for (Object dtRecordObject : (List<Object>) datalakeResponse.get('Items')) {
                    Map<String, Object> dtRecord = (Map<String, Object>) dtRecordObject;
                    if (dtRecord.containsKey('parent_id') && dtRecord.containsKey('addr_id')) {
                        String parentId = String.valueOf(dtRecord.get('parent_id'));
                        List<MVN_DataLakeCMAddress> addresses = addressesMap.containsKey(parentId) ?
                            addressesMap.get(parentId) :
                            new List<MVN_DataLakeCMAddress>();
                        String dlAddressJSON = System.JSON.serialize(dtRecordObject);
                        addresses.add((MVN_DataLakeCMAddress) System.JSON.deserialize(dlAddressJSON, MVN_DataLakeCMAddress.class));
                        addressesMap.put(parentId, addresses);
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
        return addressesMap;
    }

    /**
     * Get HCP Address Search query
     * @param accountIds    DataLake HCP Ids
     * @return  `String`
     */
    private static String getHCPAddressSearchQuery(Set<String> accountIds) {
        String hcpAddressQueryFields = 'hcp_loc.hcp_location_hcp_primary_addr_ind primary_addr_ind, hcp_loc.hcp_location_hcp_id parent_id, addr.*';
        String hcpAddressDBNames = MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_hcp_location hcp_loc,' +
            MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_location loc,' +
            MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_address addr';
        String filter = '';
        for (String accountId : accountIds) {
            filter += accountId + ',';
        }
        String whereStatements = 'addr.addr_id = loc.hco_location_addr_id AND loc.hco_cm_location_id = hcp_loc.hcp_location_loc_id AND hcp_loc.hcp_location_hcp_id in (' + filter.substringBeforeLast(',') + ')';
        return String.format(
            'SELECT {0} FROM {1} WHERE {2}',
            new List<String> {
                hcpAddressQueryFields,
                hcpAddressDBNames,
                whereStatements
            }
        );
    }

    /**
     * Get HCO Address Search query
     * @param accountIds    DataLake HCO Ids
     * @return  `String`
     */
    private static String getHCOAddressSearchQuery(Set<String> accountIds) {
        String hcoAddressQueryFields = 'hco_loc.hco_location_hco_primary_addr_ind primary_addr_ind, hco_loc.hco_location_hco_id parent_id, addr.*';
        String hcoAddressDBNames = MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_location hco_loc,' +
            MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT + 'data_semarchy_cm_pub_x_address addr';
        String filter = '';
        for (String accountId : accountIds) {
            filter += accountId + ',';
        }
        String whereStatements = 'addr.addr_valid_status = \'Y\' and addr.addr_id = hco_loc.hco_location_addr_id AND hco_loc.hco_location_hco_id in (' + filter.substringBeforeLast(',') + ')';
        return String.format(
            'SELECT {0} FROM {1} WHERE {2}',
            new List<String> {
                hcoAddressQueryFields,
                hcoAddressDBNames,
                whereStatements
            }
        );
    }
}