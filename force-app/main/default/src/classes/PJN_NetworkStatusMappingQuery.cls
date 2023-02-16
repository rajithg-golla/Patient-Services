/**
 * Query PJN_Network_Status_Mapping__mdt custom metadatas
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkStatusMappingQuery {

    /**
     * Query all Network status mappings
     * @returns `List<PJN_Network_Status_Mapping__mdt>`
     */
    public List<PJN_Network_Status_Mapping__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Message__c
            FROM
                PJN_Network_Status_Mapping__mdt
        ];
    }
}