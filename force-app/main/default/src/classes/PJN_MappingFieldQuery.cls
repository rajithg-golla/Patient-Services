/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping field query
 */
public with sharing class PJN_MappingFieldQuery {
    /**
     * query field mapping by mapping
     * @param PJN_Mapping__mdt       mapping
     */
    public List<PJN_Mapping_Field__mdt> queryByMapping(PJN_Mapping__mdt mapping) {
        return [
            SELECT
                Id,
                PJN_Source_Field_API_Name__c,
                PJN_Target_Field_API_Name__c
            FROM
                PJN_Mapping_Field__mdt
            WHERE
                PJN_Mapping__c = :mapping.Id
        ];
    }
}