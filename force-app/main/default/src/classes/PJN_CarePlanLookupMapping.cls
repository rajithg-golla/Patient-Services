/**
*  TODO: comment
* @author Mavens
* @group Careplan Mapping
* @example
*
*/
public with sharing class PJN_CarePlanLookupMapping implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * sObject mapping engine
     */
    @testVisible private PJN_MappingEngine sObjectMappingEngine = new PJN_MappingEngine();

    /**
     * care plan looup mappings
     */
    private List<PJN_Care_Plan_Lookup_Mapping__mdt> carePlanLookupMappings;

    private static Map<String, Set<String>> recordIdsToConsider {
        get {
            if(recordIdsToConsider == null) {
                recordIdsToConsider = new Map<String, Set<String>>();
            }
            return recordIdsToConsider;
        }
        set;
    }

    /**
     * Handle the trigger call
     */
    public void handle() {
        this.carePlanLookupMappings = this.getCarePlanMappings(trigger.new != null ? trigger.new.get(0).getSObjectType() : trigger.old.get(0).getSObjectType());
        Map<String, SObject> allCareplansToUpdate = new Map<String, SObject>();

        for(PJN_Care_Plan_Lookup_Mapping__mdt carePlanLookupMapping : this.carePlanLookupMappings) {
            Map<String, List<Id>> sourceObjectIds = new Map<String, List<Id>>();
            Map<String, List<Case>> carePlansToBeMapped = new Map<String, List<Case>>();
            for(SObject thisSObject : (List<SObject>)Trigger.new) {
                if(thisSObject.get(carePlanLookupMapping.PJN_Care_Plan_Lookup_API_Name__c) != null) {
                    if(Trigger.isBefore) {
                        thisSObject.put(
                            carePlanLookupMapping.PJN_Id_API_Name__c,
                            (thisSObject.get(carePlanLookupMapping.PJN_Id_API_Name__c) == null ? PJN_UUIDGenerator.randomUUID() : (String)thisSObject.get(carePlanLookupMapping.PJN_Id_API_Name__c))
                        );
                        if((Boolean)thisSObject.get(carePlanLookupMapping.PJN_Indicator_API_Name__c)) {
                            Set<String> recordIds = new Set<String>();
                            if(recordIdsToConsider.containsKey(carePlanLookupMapping.DeveloperName)) {
                                recordIds = recordIdsToConsider.get(carePlanLookupMapping.DeveloperName);
                            }
                            recordIds.add((String)thisSObject.get(carePlanLookupMapping.PJN_Id_API_Name__c));
                            recordIdsToConsider.put(carePlanLookupMapping.DeveloperName, recordIds);
                        }
                        thisSObject.put(carePlanLookupMapping.PJN_Indicator_To_Update_API_Name__c, false);
                    } else if(Trigger.isAfter && !recordIdsToConsider.isEmpty()
                                              && recordIdsToConsider.containsKey(carePlanLookupMapping.DeveloperName)
                                              && recordIdsToConsider.get(carePlanLookupMapping.DeveloperName).contains((String)thisSObject.get(carePlanLookupMapping.PJN_Id_API_Name__c))) {
                        List<Id> sourceIds = new List<Id>();
                        if(sourceObjectIds.containsKey(carePlanLookupMapping.DeveloperName)) {
                            sourceIds = sourceObjectIds.get(carePlanLookupMapping.DeveloperName);
                        }
                        sourceIds.add(thisSObject.Id);
                        sourceObjectIds.put(carePlanLookupMapping.DeveloperName, sourceIds);
                        List<Case> careplans = new List<Case>();
                        if(carePlansToBeMapped.containsKey(carePlanLookupMapping.DeveloperName)) {
                            careplans = carePlansToBeMapped.get(carePlanLookupMapping.DeveloperName);
                        }
                        careplans.add(
                            new Case(
                                Id = (Id)thisSObject.get(carePlanLookupMapping.PJN_Care_Plan_Lookup_API_Name__c)
                            )
                        );
                        carePlansToBeMapped.put(carePlanLookupMapping.DeveloperName, careplans);
                    }
                }
            }
            if(sourceObjectIds.containsKey(carePlanLookupMapping.DeveloperName) && carePlansToBeMapped.containsKey(carePlanLookupMapping.DeveloperName)) {
                Map<String, List<Id>> sourceObjectMappingIds = new Map<String, List<Id>> {
                    'record' => sourceObjectIds.get(carePlanLookupMapping.DeveloperName),
                    'recordlabels' => sourceObjectIds.get(carePlanLookupMapping.DeveloperName),
                    'recorddates' => sourceObjectIds.get(carePlanLookupMapping.DeveloperName)
                };
                this.sObjectMappingEngine.initiate(carePlanLookupMapping.PJN_Mapping_Job_Name__c);
                Map<String, SObject> careplansToUpdate = sObjectMappingEngine.run(
                    sourceObjectMappingIds,
                    carePlansToBeMapped.get(carePlanLookupMapping.DeveloperName)
                );
                allCareplansToUpdate = this.getMergedCareplans(allCareplansToUpdate, careplansToUpdate);
            }
        }
        update allCareplansToUpdate.values();
    }

    private Map<String, SObject> getMergedCareplans(Map<String, SObject> allCareplansToUpdate, Map<String, SObject> careplansToUpdate) {
        for(String key : careplansToUpdate.keySet()) {
            SObject carePlanToUpdate = careplansToUpdate.get(key);
            if(allCareplansToUpdate.containsKey(key)) {
                SObject carePlanToUpdate1 = allCareplansToUpdate.get(key);
                Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
                for(String caseFieldName : caseFields.keySet()) {
                    if(carePlanToUpdate.get(caseFieldName) == null && carePlanToUpdate1.get(caseFieldName) != null) {
                        carePlanToUpdate.put(caseFieldName, carePlanToUpdate1.get(caseFieldName));
                    }
                }
            }
            allCareplansToUpdate.put(key, carePlanToUpdate);
        }
        return allCareplansToUpdate;
    }

    /**
     * get care plan mappings setup
     * @param thisSObjectType
     * @returns `List<PJN_Care_Plan_Lookup_Mapping__mdt>`
     */
    private List<PJN_Care_Plan_Lookup_Mapping__mdt> getCarePlanMappings(SObjectType thisSObjectType) {
        return [
            SELECT
                DeveloperName,
                PJN_Care_Plan_Lookup_API_Name__c,
                PJN_Indicator_API_Name__c,
                PJN_Indicator_To_Update_API_Name__c,
                PJN_Mapping_Job_Name__c,
                PJN_Id_API_Name__c
            FROM
                PJN_Care_Plan_Lookup_Mapping__mdt
            WHERE
                PJN_SObject_API_Name__c = :thisSObjectType.getDescribe().getName()
            AND
                PJN_Active__c = true
        ];
    }
}