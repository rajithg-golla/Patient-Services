public with sharing class PJN_FulfillmentRequestCreationHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    private static Map<String, List<PJN_Fulfillment_Request_Creation__mdt>> fulfillmentRequestMappings {
        get {
            Map<String, List<PJN_Fulfillment_Request_Creation__mdt>> fulfillmentRequestMappings = new Map<String, List<PJN_Fulfillment_Request_Creation__mdt>>();
            for(PJN_Fulfillment_Request_Creation__mdt thisFulFillmentMapping : [SELECT
                                                                                    Id,
                                                                                    PJN_Request_Target_Field_API_Name__c,
                                                                                    PJN_Mapping_Object_Type_Name__c,
                                                                                    PJN_Record_Type_Developer_Name__c,
                                                                                    PJN_Program__r.DeveloperName
                                                                                FROM
                                                                                    PJN_Fulfillment_Request_Creation__mdt
                                                                            ]) {
                List<PJN_Fulfillment_Request_Creation__mdt> fulfillmentRequestMappingList = new List<PJN_Fulfillment_Request_Creation__mdt>();
                if(fulfillmentRequestMappings.containsKey(thisFulFillmentMapping.PJN_Program__r.DeveloperName + '|' + thisFulFillmentMapping.PJN_Record_Type_Developer_Name__c)) {
                    fulfillmentRequestMappingList = fulfillmentRequestMappings.get(thisFulFillmentMapping.PJN_Program__r.DeveloperName + '|' + thisFulFillmentMapping.PJN_Record_Type_Developer_Name__c);
                }
                fulfillmentRequestMappingList.add(thisFulFillmentMapping);
                fulfillmentRequestMappings.put(thisFulFillmentMapping.PJN_Program__r.DeveloperName + '|' + thisFulFillmentMapping.PJN_Record_Type_Developer_Name__c, fulfillmentRequestMappingList);
            }
            return fulfillmentRequestMappings;
        }
    }

    public void handle() {
        Map<String, Map<String, List<Id>>> fulFillmentRequestMappingByProgram = new Map<String, Map<String, List<Id>>>();
        Map<String, List<PJN_Fulfillment_Request__c>> fulFillmentRequestToBeMappedByProgram = new Map<String, List<PJN_Fulfillment_Request__c>>();
        Map<Id, String> recordTypeDeveloperNamesById = this.getRecordTypeDeveloperNames();
        for(PJN_FulFillment_Request__c thisFulFillmentRequest : (List<PJN_Fulfillment_Request__c>) trigger.new) {
            if(thisFulFillmentRequest.PJN_Date_Processed__c == null) {
                thisFulFillmentRequest.PJN_Creation_UUID__c = (thisFulFillmentRequest.PJN_Creation_UUID__c == null ? PJN_UUIDGenerator.randomUUID() : thisFulFillmentRequest.PJN_Creation_UUID__c);
                Map<String, List<Id>> fulFillmentRequestMapping = new Map<String, List<Id>>();
                if(fulFillmentRequestMappingByProgram.containsKey(thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId)) {
                    fulFillmentRequestMapping = fulFillmentRequestMappingByProgram.get(thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId);
                }

                List<PJN_Fulfillment_Request__c> fulFillmentRequestToBeMapped = new List<PJN_Fulfillment_Request__c>();
                if(fulFillmentRequestToBeMappedByProgram.containsKey(thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId)) {
                    fulFillmentRequestToBeMapped = fulFillmentRequestToBeMappedByProgram.get(thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId);
                }
                if (fulfillmentRequestMappings.containsKey(thisFulFillmentRequest.PJN_Program_DeveloperName__c + '|' + recordTypeDeveloperNamesById.get(thisFulFillmentRequest.RecordTypeId))) {
                    for(PJN_Fulfillment_Request_Creation__mdt thisFulFillmentMapping : fulfillmentRequestMappings.get(thisFulFillmentRequest.PJN_Program_DeveloperName__c + '|' + recordTypeDeveloperNamesById.get(thisFulFillmentRequest.RecordTypeId))) {
                        Id lookupId = (Id) thisFulFillmentRequest.get(thisFulFillmentMapping.PJN_Request_Target_Field_API_Name__c);
                        if(lookupId != null) {
                            List<Id> sourceObjectIds = new List<Id>();
                            if(fulFillmentRequestMapping.containsKey(thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c)) {
                                sourceObjectIds = fulFillmentRequestMapping.get(thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c);
                            }
                            sourceObjectIds.add(lookupId);
                            fulFillmentRequestMapping.put(thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c, sourceObjectIds);
                            fulFillmentRequestMapping.put(thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c + 'labels', sourceObjectIds);
                            fulFillmentRequestMapping.put(thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c + 'dates', sourceObjectIds);
                        }
                    }
                    fulFillmentRequestToBeMapped.add(thisFulFillmentRequest);

                    fulFillmentRequestMappingByProgram.put(
                        thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId,
                        fulFillmentRequestMapping
                    );
                    fulFillmentRequestToBeMappedByProgram.put(
                        thisFulFillmentRequest.PJN_Program_DeveloperName__c + thisFulFillmentRequest.RecordTypeId,
                        fulFillmentRequestToBeMapped
                    );
                }
            }
        }

        Map<String, SObject> mappedFulFillmentRequests = new Map<String, SObject>();
        for(String programDeveloperNameAndRecTypeId : fulFillmentRequestMappingByProgram.keySet()) {
            Map<String, List<Id>> fulFillmentRequestMapping = fulFillmentRequestMappingByProgram.get(programDeveloperNameAndRecTypeId);
            List<PJN_Fulfillment_Request__c> fulFillmentRequestToBeMapped = fulFillmentRequestToBeMappedByProgram.get(programDeveloperNameAndRecTypeId);
            if (fulFillmentRequestToBeMapped.isEmpty()) {
                continue;
            }
            PJN_MappingEngine fulfillmentRequestMappingEngine = new PJN_MappingEngine();
            fulfillmentRequestMappingEngine.initiate(fulFillmentRequestToBeMapped[0].PJN_Program_DeveloperName__c + '_Fulfillment');
            fulfillmentRequestMappingEngine.identifier = 'PJN_Creation_UUID__c';
            mappedFulFillmentRequests.putAll(
                fulfillmentRequestMappingEngine.run(
                    fulFillmentRequestMapping,
                    fulFillmentRequestToBeMapped
                )
            );
        }

        if(!mappedFulFillmentRequests.isEmpty()) {
            for(PJN_Fulfillment_Request__c thisFulfillmentRequest : (List<PJN_Fulfillment_Request__c>) trigger.new) {
                thisFulfillmentRequest = (PJN_Fulfillment_Request__c) mappedFulFillmentRequests.get(thisFulfillmentRequest.PJN_Creation_UUID__c);
            }
        }
    }

    private Map<Id, String> getRecordTypeDeveloperNames() {
        Map<Id, String> recordTypeDeveloperNamesById = new Map<Id, String>();
        Set<Id> recordTypeIds = new Set<Id>();
        for(PJN_Fulfillment_Request__c thisFulfillmentRequest : (List<PJN_Fulfillment_Request__c>) trigger.new) {
            recordTypeIds.add(thisFulfillmentRequest.RecordTypeId);
        }
        for(RecordType thisRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE Id IN :recordTypeIds]) {
            recordTypeDeveloperNamesById.put(thisRecordType.Id, thisRecordType.DeveloperName);
        }
        return recordTypeDeveloperNamesById;
    }
}