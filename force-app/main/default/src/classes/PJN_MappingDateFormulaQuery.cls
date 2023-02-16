/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping date formula query
 */
public with sharing class PJN_MappingDateFormulaQuery {

    static Map<Id, List<PJN_Mapping_Date_Formula__mdt>> mappingDateFormulasById;
    /**
     * query date formula mapping by mapping
     * @param PJN_Mapping__mdt       mapping
     */
    public List<PJN_Mapping_Date_Formula__mdt> queryByMapping(PJN_Mapping__mdt mapping) {
        if (mappingDateFormulasById == null) {
            mappingDateFormulasById = new Map<Id, List<PJN_Mapping_Date_Formula__mdt>>();
        }

        if (!mappingDateFormulasById.containsKey(mapping.Id)) {
            mappingDateFormulasById.put(mapping.Id,
                [
                    SELECT
                        Id,
                        PJN_Formula__c,
                        PJN_Days_To_Add__c,
                        PJN_Source_Field_API_Name__c,
                        PJN_Target_Field_API_Name__c
                    FROM
                        PJN_Mapping_Date_Formula__mdt
                    WHERE
                        PJN_Mapping__c = :mapping.Id
                ]
            );
        }
        return mappingDateFormulasById.get(mapping.Id);
    }
}