public with sharing class PJN_EventCreationHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    private static Map<String, List<PJN_Event_Creation__mdt>> eventMappings {
        get {
            Map<String, List<PJN_Event_Creation__mdt>> eventMappings = new Map<String, List<PJN_Event_Creation__mdt>>();
            for(PJN_Event_Creation__mdt thisEventMapping : [SELECT
                                                                    Id,
                                                                    PJN_Request_Target_Field_API_Name__c,
                                                                    PJN_Mapping_Object_Type_Name__c,
                                                                    PJN_Record_Type_Developer_Name__c,
                                                                    PJN_Program__r.DeveloperName
                                                                FROM
                                                                    PJN_Event_Creation__mdt
                                                            ]) {
                List<PJN_Event_Creation__mdt> eventMappingList = new List<PJN_Event_Creation__mdt>();
                if(eventMappings.containsKey(thisEventMapping.PJN_Program__r.DeveloperName + '|' + thisEventMapping.PJN_Record_Type_Developer_Name__c)) {
                    eventMappingList = eventMappings.get(thisEventMapping.PJN_Program__r.DeveloperName + '|' + thisEventMapping.PJN_Record_Type_Developer_Name__c);
                }
                eventMappingList.add(thisEventMapping);
                eventMappings.put(thisEventMapping.PJN_Program__r.DeveloperName + '|' + thisEventMapping.PJN_Record_Type_Developer_Name__c, eventMappingList);
            }
            return eventMappings;
        }
    }

    public void handle() {
        Map<String, Map<String, List<Id>>> eventMappingByProgram = new Map<String, Map<String, List<Id>>>();
        Map<String, List<PJN_Event__c>> eventToBeMappedByProgram = new Map<String, List<PJN_Event__c>>();
        Map<Id, String> recordTypeDeveloperNamesById = this.getRecordTypeDeveloperNames();
        for(PJN_Event__c thisEvent : (List<PJN_Event__c>) trigger.new) {
            thisEvent.PJN_Creation_UUID__c = (thisEvent.PJN_Creation_UUID__c == null ? PJN_UUIDGenerator.randomUUID() : thisEvent.PJN_Creation_UUID__c);
            Map<String, List<Id>> eventMapping = new Map<String, List<Id>>();
            if(eventMappingByProgram.containsKey(thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId)) {
                eventMapping = eventMappingByProgram.get(thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId);
            }

            List<PJN_Event__c> eventToBeMapped = new List<PJN_Event__c>();
            if(eventToBeMappedByProgram.containsKey(thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId)) {
                eventToBeMapped = eventToBeMappedByProgram.get(thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId);
            }
            if (eventMappings.containsKey(thisEvent.PJN_Program_DeveloperName__c + '|' + recordTypeDeveloperNamesById.get(thisEvent.RecordTypeId))) {
                for(PJN_Event_Creation__mdt thisEventMapping : eventMappings.get(thisEvent.PJN_Program_DeveloperName__c + '|' + recordTypeDeveloperNamesById.get(thisEvent.RecordTypeId))) {
                    Id lookupId = (Id) thisEvent.get(thisEventMapping.PJN_Request_Target_Field_API_Name__c);
                    if(lookupId != null) {
                        List<Id> sourceObjectIds = new List<Id>();
                        if(eventMapping.containsKey(thisEventMapping.PJN_Mapping_Object_Type_Name__c)) {
                            sourceObjectIds = eventMapping.get(thisEventMapping.PJN_Mapping_Object_Type_Name__c);
                        }
                        sourceObjectIds.add(lookupId);
                        eventMapping.put(thisEventMapping.PJN_Mapping_Object_Type_Name__c, sourceObjectIds);
                        eventMapping.put(thisEventMapping.PJN_Mapping_Object_Type_Name__c + 'labels', sourceObjectIds);
                        eventMapping.put(thisEventMapping.PJN_Mapping_Object_Type_Name__c + 'dates', sourceObjectIds);
                    }
                }
                eventToBeMapped.add(thisEvent);

                eventMappingByProgram.put(
                    thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId,
                    eventMapping
                );
                eventToBeMappedByProgram.put(
                    thisEvent.PJN_Program_DeveloperName__c + thisEvent.RecordTypeId,
                    eventToBeMapped
                );
            }
        }

        Map<String, SObject> mappedEvents = new Map<String, SObject>();
        for(String programDeveloperNameAndRecTypeId : eventMappingByProgram.keySet()) {
            Map<String, List<Id>> eventMapping = eventMappingByProgram.get(programDeveloperNameAndRecTypeId);
            List<PJN_Event__c> eventToBeMapped = eventToBeMappedByProgram.get(programDeveloperNameAndRecTypeId);
            if (eventToBeMapped.isEmpty()) {
                continue;
            }
            PJN_MappingEngine eventMappingEngine = new PJN_MappingEngine();
            eventMappingEngine.initiate(eventToBeMapped[0].PJN_Program_DeveloperName__c + '_Event');
            eventMappingEngine.identifier = 'PJN_Creation_UUID__c';
            mappedEvents.putAll(
                eventMappingEngine.run(
                    eventMapping,
                    eventToBeMapped
                )
            );
        }

        if(!mappedEvents.isEmpty()) {
            for(PJN_Event__c thisEvent : (List<PJN_Event__c>) trigger.new) {
                thisEvent = (PJN_Event__c) mappedEvents.get(thisEvent.PJN_Creation_UUID__c);
            }
        }
    }

    private Map<Id, String> getRecordTypeDeveloperNames() {
        Map<Id, String> recordTypeDeveloperNamesById = new Map<Id, String>();
        Set<Id> recordTypeIds = new Set<Id>();
        for(PJN_Event__c thisEvent : (List<PJN_Event__c>) trigger.new) {
            recordTypeIds.add(thisEvent.RecordTypeId);
        }
        for(RecordType thisRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE Id IN :recordTypeIds]) {
            recordTypeDeveloperNamesById.put(thisRecordType.Id, thisRecordType.DeveloperName);
        }
        return recordTypeDeveloperNamesById;
    }
}