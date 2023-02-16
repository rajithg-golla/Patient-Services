/**
 * Maps Network Status to messages
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkStatusMapping {

    /**
     * Network Status mapping query wrapper
     */
    @TestVisible
    private static PJN_NetworkStatusMappingQuery networkStatusMappingQuery = new PJN_NetworkStatusMappingQuery();

    /**
     * All Network status mappings by status
     */
    private static Map<String, PJN_Network_Status_Mapping__mdt> networkstatusMappingByStatus {
        get {
            if (networkstatusMappingByStatus != null && !networkstatusMappingByStatus.isEmpty()) {
                return networkstatusMappingByStatus;
            }

            networkstatusMappingByStatus = new Map<String, PJN_Network_Status_Mapping__mdt>();

            for (PJN_Network_Status_Mapping__mdt networkStatusMapping : networkStatusMappingQuery.queryAll()) {
                networkstatusMappingByStatus.put(networkStatusMapping.DeveloperName, networkStatusMapping);
            }

            return networkstatusMappingByStatus;
        } set;
    }

    /**
     * Get message for Network status mapping developer name provided
     * @param networkStatus Network status mapping developer name
     * @returns `String`
     */
    public static String getMessageForNetwokStatus(String networkStatus) {
        if (String.isBlank(networkStatus)) {
            return null;
        }

        return networkstatusMappingByStatus.containsKey(networkStatus) ?
            networkstatusMappingByStatus.get(networkStatus).PJN_Message__c :
            null;
    }
}