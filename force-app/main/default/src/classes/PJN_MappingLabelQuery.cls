/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping Label query
 */
public with sharing class PJN_MappingLabelQuery {

    private static Map<Id, PJN_Mapping__mdt> mappingsWithMappingLabels {
        get {
            if (mappingsWithMappingLabels == null) {
                mappingsWithMappingLabels = new Map<Id, PJN_Mapping__mdt> (
                    [
                        SELECT
                            Id,
                            (
                                SELECT
                                    Id,
                                    PJN_Source_Field_API_Name__c,
                                    PJN_Target_Field_API_Name__c,
                                    PJN_Label_Text_Area__c
                                FROM
                                    PJN_Mapping_Labels__r
                            )
                        FROM
                            PJN_Mapping__mdt
                    ]
                );
            }
            return mappingsWithMappingLabels;
        }
        set;
    }
    /**
     * query record type mapping by mapping
     * @param PJN_Mapping__mdt       mapping
     */
    public List<PJN_Mapping_Label__mdt> queryByMapping(PJN_Mapping__mdt mapping) {
        if (mappingsWithMappingLabels.containsKey(mapping.Id)) {
            return mappingsWithMappingLabels.get(mapping.Id).PJN_Mapping_Labels__r;
        }

        return new List<PJN_Mapping_Label__mdt>();
    }
}