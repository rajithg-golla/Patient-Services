/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping record types
 */
public with sharing class PJN_MappingEngineRecordTypeHdlr extends PJN_MappingEngineHdlr {
    /**
     * record type mapping query
     */
    @testVisible private PJN_MappingRecordTypeQuery mappingRecordTypeQuery = new PJN_MappingRecordTypeQuery();

    /**
     * record type mapping
     */
    private PJN_Mapping_Record_Type__mdt recordTypeMapping;

    /**
     * use mapping implementation
     * @param PJN_Mapping__mdt       mapping
     */
    public override void useMapping(PJN_Mapping__mdt mapping) {
        try {
            this.recordTypeMapping = this.mappingRecordTypeQuery.queryByMapping(mapping);
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
        targetObject.put(this.recordTypeMapping.PJN_Target_Field_API_Name__c, this.getRecordType(targetObject));
        return targetObject;
    }

    /**
     * get record type by developer name
     * @param SObject       targetObject
     * @returns Id
     */
    private Id getRecordType(SObject targetObject) {
        return targetObject.getSObjectType()
                           .getDescribe()
                           .getRecordTypeInfosByDeveloperName()
                           .get(recordTypeMapping.PJN_Record_Type_API_Name__c)
                           .getRecordTypeId();
    }
}