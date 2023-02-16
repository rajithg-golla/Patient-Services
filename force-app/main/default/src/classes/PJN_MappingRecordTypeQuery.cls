/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping record type query
 */
public with sharing class PJN_MappingRecordTypeQuery {

    static Map<Id, PJN_Mapping_Record_Type__mdt> mappingRecTypesById;
    /**
     * query record type mapping by mapping
     * @param PJN_Mapping__mdt       mapping
     */
    public PJN_Mapping_Record_Type__mdt queryByMapping(PJN_Mapping__mdt mapping) {
        if (mappingRecTypesById == null) {
            mappingRecTypesById = new Map<Id, PJN_Mapping_Record_Type__mdt>();
        }

        if (!mappingRecTypesById.containsKey(mapping.Id)) {
            mappingRecTypesById.put(mapping.Id,
                [
                    SELECT
                        Id,
                        PJN_Record_Type_API_Name__c,
                        PJN_Target_Field_API_Name__c
                    FROM
                        PJN_Mapping_Record_Type__mdt
                    WHERE
                        PJN_Mapping__c = :mapping.Id
                ]
            );
        }
        return mappingRecTypesById.get(mapping.Id);
    }
}