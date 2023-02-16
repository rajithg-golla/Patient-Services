/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping record types
 */
public with sharing class PJN_MappingEngineQueueHdlr extends PJN_MappingEngineHdlr {
    /**
     * queue mapping query
     */
    @testVisible private PJN_MappingQueueQuery mappingQueueQuery = new PJN_MappingQueueQuery();

    /**
     * queue query
     */
    @testVisible private PJN_QueueQuery queueQuery = new PJN_QueueQuery();

    /**
     * record type mapping
     */
    private PJN_Mapping_Queue__mdt queueMapping;

    /**
     * use mapping implementation
     * @param PJN_Mapping__mdt       mapping
     */
    public override void useMapping(PJN_Mapping__mdt mapping) {
        try {
            this.queueMapping = this.mappingQueueQuery.queryByMapping(mapping);
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
        targetObject.put(this.queueMapping.PJN_Target_Field_API_Name__c, this.getQueue());
        return targetObject;
    }

    /**
     * get queue by developer name
     * @param SObject       targetObject
     * @returns Id
     */
    private Id getQueue() {
        return this.queueQuery.queryByDeveloperName(this.queueMapping.PJN_Queue_API_Name__c).Id;
    }
}