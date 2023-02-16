public with sharing class PJN_MappingEngineLabelHdlr extends PJN_MappingEngineHdlr {
    /**
     * queue mapping query
     */
    @testVisible private PJN_MappingLabelQuery mappingLabelQuery = new PJN_MappingLabelQuery();

    /**
     * label mapping
     */
    private List<PJN_Mapping_Label__mdt> labelMappings;

    /**
     * use mapping implementation
     * @param PJN_Mapping__mdt       mapping
     */
    public override void useMapping(PJN_Mapping__mdt mapping) {
        try {
            this.labelMappings = this.mappingLabelQuery.queryByMapping(mapping);
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
        for(PJN_Mapping_Label__mdt thisLabelMapping : this.labelMappings) {
            String sourceFieldValue;
            List<String> labelFields = new List<String>();
            if(sourceObject != null && thisLabelMapping.PJN_Source_Field_API_Name__c != null) {
                for(String sourceFieldAPIName : thisLabelMapping.PJN_Source_Field_API_Name__c.split(',')) {
                    sourceFieldValue = String.valueOf(super.getFieldValue(sourceObject, sourceFieldAPIName));
                    labelFields.add(sourceFieldValue);
                }
            }
            targetObject.put(
                thisLabelMapping.PJN_Target_Field_API_Name__c,
                String.format(
                    thisLabelMapping.PJN_Label_Text_Area__c.replaceAll('\'','\'\''),
                    labelFields
                )
            );
        }
        return targetObject;
    }

    /**
     * get source fields implementation
     * @returns List<String>
     */
    @testVisible protected override List<String> getSourceFields() {
        Set<String> fields = new Set<String> {'Id'};
        for(PJN_Mapping_Label__mdt thisLabelMapping : this.labelMappings) {
            if(thisLabelMapping.PJN_Source_Field_API_Name__c != null) {
                fields.addAll(thisLabelMapping.PJN_Source_Field_API_Name__c.split(','));
            }
        }
        return new List<String>(fields);
    }
}