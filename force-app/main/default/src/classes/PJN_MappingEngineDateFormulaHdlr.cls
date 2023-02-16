/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping date formula
 */
public with sharing class PJN_MappingEngineDateFormulaHdlr extends PJN_MappingEngineHdlr {
    /**
     * queue mapping query
     */
    @testVisible private PJN_MappingDateFormulaQuery mappingDateFormulaQuery = new PJN_MappingDateFormulaQuery();

    /**
     * DateFormula mapping
     */
    private List<PJN_Mapping_Date_Formula__mdt> dateFormulaMappings;

    /**
     * use mapping implementation
     * @param PJN_Mapping__mdt       mapping
     */
    public override void useMapping(PJN_Mapping__mdt mapping) {
        try {
            this.dateFormulaMappings = this.mappingDateFormulaQuery.queryByMapping(mapping);
        } catch(System.QueryException qE) {
            throw new PJN_MappingEngineException('No specific Mapping for ' + mapping.Label + '(' + mapping.DeveloperName + ') found.');
        }
    }

    /**
     * map record
     * @param SObject       sourceObject
     * @param SObject       targetObject
     * @returns SObject
     */
    @testVisible protected override SObject mapRecord(SObject sourceObject, SObject targetObject) {
        for(PJN_Mapping_Date_Formula__mdt thisDateFormulaMapping : this.dateFormulaMappings) {
            Object fieldValue;
            switch on thisDateFormulaMapping.PJN_Formula__c {
                when 'NOW' {
                    fieldValue = System.now();
                }
                when 'TODAY' {
                    fieldValue = System.today();
                }
                when 'FIELD' {
                    if(sourceObject != null) {
                        fieldValue = super.getFieldValue(sourceObject, thisDateFormulaMapping.PJN_Source_Field_API_Name__c);
                    }
                }
            }
            Schema.DisplayType targetFieldType = targetObject.getSObjectType().getDescribe().fields.getMap().get(thisDateFormulaMapping.PJN_Target_Field_API_Name__c).getDescribe().getType();
            if(targetFieldType == Schema.DisplayType.DATE) {
                fieldValue = ((Date)fieldValue).addDays(Integer.valueOf(thisDateFormulaMapping.PJN_Days_To_Add__c));
                targetObject.put(thisDateFormulaMapping.PJN_Target_Field_API_Name__c, fieldValue);
            } else if(targetFieldType == Schema.DisplayType.DATETIME) {
                fieldValue = ((Datetime)fieldValue).addDays(Integer.valueOf(thisDateFormulaMapping.PJN_Days_To_Add__c));
                targetObject.put(thisDateFormulaMapping.PJN_Target_Field_API_Name__c, fieldValue);
            }
        }
        return targetObject;
    }

    /**
     * get source fields implementation
     * @returns List<String>
     */
    @testVisible protected override List<String> getSourceFields() {
        Set<String> fields = new Set<String> {'Id'};
        for(PJN_Mapping_Date_Formula__mdt thisDateFormulaMapping : this.dateFormulaMappings) {
            if(thisDateFormulaMapping.PJN_Source_Field_API_Name__c != null) {
                fields.add(thisDateFormulaMapping.PJN_Source_Field_API_Name__c);
            }
        }
        return new List<String>(fields);
    }
}