/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping queue query
 */
public with sharing class PJN_MappingQueueQuery {
    /**
     * query record type mapping by mapping
     * @param PJN_Mapping__mdt       mapping
     */
    public PJN_Mapping_Queue__mdt queryByMapping(PJN_Mapping__mdt mapping) {
        return [
            SELECT
                Id,
                PJN_Queue_API_Name__c,
                PJN_Target_Field_API_Name__c
            FROM
                PJN_Mapping_Queue__mdt
            WHERE
                PJN_Mapping__c = :mapping.Id
        ];
    }
}