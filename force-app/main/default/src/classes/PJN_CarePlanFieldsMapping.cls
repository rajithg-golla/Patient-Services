/**
 * @author Mavens
 * @date Apr 2019
 * @description Handler that runs the mapping engine to stamp fields from the careplan to its related records
 */
public with sharing class PJN_CarePlanFieldsMapping implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * sObject mapping engine
     */
    @testVisible private PJN_MappingEngine sObjectMappingEngine = new PJN_MappingEngine();

    /**
     * Handle the trigger call
     */
    public void handle() {
        PJN_Care_Plan_Field_Mapping__mdt carePlanFieldMapping = this.getCarePlanMappings(trigger.new != null ? trigger.new.get(0).getSObjectType() : trigger.old.get(0).getSObjectType());

        List<Id> carePlanIds = new List<Id>();
        List<SObject> sObjectsToBeMapped = new List<SObject>();

        for (SObject thisSObject : (List<SObject>)Trigger.new) {
            if(thisSObject.get(carePlanFieldMapping.PJN_Care_Plan_Lookup_API_Name__c) != null) {
                thisSObject.put(
                    carePlanFieldMapping.PJN_Id_API_Name__c,
                    (thisSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c) == null ? PJN_UUIDGenerator.randomUUID() : (String)thisSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c))
                );

                carePlanIds.add((String)thisSObject.get(carePlanFieldMapping.PJN_Care_Plan_Lookup_API_Name__c));
                sObjectsToBeMapped.add(thisSObject);
            }
        }

        Map<String, List<Id>> sourceObjectIds = new Map<String, List<Id>> {
            'careplan' => carePlanIds,
            'careplanlabels' => carePlanIds,
            'careplandates' => carePlanIds
        };

        if(!sObjectsToBeMapped.isEmpty()) {
            Map<String, SObject> mappedSObjects = new Map<String, SObject>();
            this.sObjectMappingEngine.initiate(carePlanFieldMapping.PJN_Mapping_Job_Name__c);
            this.sObjectMappingEngine.identifier = carePlanFieldMapping.PJN_Id_API_Name__c;
            mappedSObjects.putAll(
                sObjectMappingEngine.run(
                    sourceObjectIds,
                    sObjectsToBeMapped
                )
            );

            if(!mappedSObjects.isEmpty()) {
                for(SObject thisSObject : (List<SObject>) trigger.new) {
                    thisSObject = mappedSObjects.get((String)thisSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c));
                }
            }
        }
    }

    /**
     * get care plan mappings setup
     * @param   SObjectType         thisSObjectType
     * @returns  PJN_Care_Plan_Field_Mapping__mdt
     */
    private PJN_Care_Plan_Field_Mapping__mdt getCarePlanMappings(SObjectType thisSObjectType) {
        return [
            SELECT
                PJN_Care_Plan_Lookup_API_Name__c,
                PJN_Id_API_Name__c,
                PJN_Mapping_Job_Name__c
            FROM
                PJN_Care_Plan_Field_Mapping__mdt
            WHERE
                PJN_SObject_API_Name__c = :thisSObjectType.getDescribe().getName()
            AND
                PJN_Active__c = true
        ];
    }
}