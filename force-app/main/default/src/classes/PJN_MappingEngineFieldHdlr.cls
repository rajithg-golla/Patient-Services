/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping fields
 */
public with sharing class PJN_MappingEngineFieldHdlr extends PJN_MappingEngineHdlr {
    /**
     * queue mapping query
     */
    @testVisible private PJN_MappingFieldQuery mappingFieldQuery = new PJN_MappingFieldQuery();

    /**
     * field mapping
     */
    private List<PJN_Mapping_Field__mdt> fieldMappings;

    /**
     * use mapping implementation
     * @param PJN_Mapping__mdt       mapping
     */
    public override void useMapping(PJN_Mapping__mdt mapping) {
        try {
            this.fieldMappings = this.mappingFieldQuery.queryByMapping(mapping);
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
        Schema.DescribeSObjectResult targetObjectDescribe = targetObject.getSObjectType().getDescribe();
        for(PJN_Mapping_Field__mdt thisFieldMapping : this.fieldMappings) {
            Schema.DescribeFieldResult fieldDescribe = targetObjectDescribe.fields.getMap().get(thisFieldMapping.PJN_Target_Field_API_Name__c).getDescribe();
            Object value = super.getFieldValue(sourceObject, thisFieldMapping.PJN_Source_Field_API_Name__c);
            if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN
                    && value == null) {
                value = false;
            }
            targetObject.put(thisFieldMapping.PJN_Target_Field_API_Name__c, value);
        }
        return targetObject;
    }

    /**
     * get source fields implementation
     * @returns List<String>
     */
    @testVisible protected override List<String> getSourceFields() {
        Set<String> fields = new Set<String> {'Id'};
        for(PJN_Mapping_Field__mdt thisFieldMapping : this.fieldMappings) {
            fields.add(thisFieldMapping.PJN_Source_Field_API_Name__c);
        }
        return new List<String>(fields);
    }
}