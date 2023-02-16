/**
 * @author      Mavens
 * @group       Fulfillment
 * @description used by NEW override on fulfillment request
 */
public with sharing class PJN_NewFulfillmentRequestCtrl {
    /**
     * fulfillment request creation query
     */
    @testVisible private static PJN_FulfillmentRequestCreationQuery fulfillmentRequestCreationQuery = new PJN_FulfillmentRequestCreationQuery();

    /**
     * mapping engine
     */
    @testVisible private static PJN_MappingEngine fulfillmentRequestMappingEngine = new PJN_MappingEngine();

    /**
     * fulfillment request creation mappings
     */
    private static List<PJN_Fulfillment_Request_Creation__mdt> fulFillmentMappings;

    /**
     * populate lookups and run mapping engine to populate all fields as configured
     * @param   PJN_Fulfillment_Request__c        fulfillmentRequest
     * @returns  PJN_Fulfillment_Request__c
     */
    @auraEnabled public static PJN_Fulfillment_Request__c getFulfillmentRequest(PJN_Fulfillment_Request__c fulfillmentRequest) {
        try {
            if (fulfillmentRequest.PJN_Care_Plan__c == null) {
                return fulfillmentRequest;
            }
            fulFillmentMappings = getFulfillmentRequestMappings(fulfillmentRequest);

            if(fulFillmentMappings.isEmpty()) {
                return fulfillmentRequest;
            }

            Case careplan = getCarePlanWithLookupFields(fulfillmentRequest.PJN_Care_Plan__c);

            fulfillmentRequest = populateLookupFields(careplan, fulfillmentRequest);
            fulfillmentRequest.PJN_Creation_UUID__c = PJN_UUIDGenerator.randomUUID();
            fulfillmentRequest.PJN_Program_DeveloperName__c = careplan.PJN_Program_DeveloperName__c;

            fulfillmentRequestMappingEngine.initiate(careplan.PJN_Program_DeveloperName__c + '_Fulfillment');
            fulfillmentRequestMappingEngine.identifier = 'PJN_Creation_UUID__c';
            fulfillmentRequest = (PJN_Fulfillment_Request__c) fulfillmentRequestMappingEngine.run(
                createMappings(careplan),
                fulfillmentRequest
            );

            return fulfillmentRequest;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }

    }

    /**
     * get fulfillment request mappings
     * @param   PJN_Fulfillment_Request__c        fulfillmentRequest
     * @returns  List<PJN_Fulfillment_Request_Creation__mdt>
     */
    private static List<PJN_Fulfillment_Request_Creation__mdt> getFulfillmentRequestMappings(PJN_Fulfillment_Request__c fulfillmentRequest) {
        String programDeveloperName = getProgramDeveloperName(fulfillmentRequest.PJN_Care_Plan__c);
        String recordTypeDeveloperName = getRecordTypeDeveloperName(fulfillmentRequest.RecordTypeId);
        return fulfillmentRequestCreationQuery.queryByProgramDeveloperNameAndRecordTypeDeveloperName(programDeveloperName, recordTypeDeveloperName);
    }

    /**
     * get Program Developer Name
     * @param   Id        careplanId
     * @returns  String
     */
    private static String getProgramDeveloperName(Id careplanId) {
        return [
            SELECT
                Id,
                PJN_Program_DeveloperName__c
            FROM
                Case
            WHERE
                Id = :careplanId
        ].PJN_Program_DeveloperName__c;
    }

    /**
     * Get record tyope developer name. If record type id is null get the defaul record type for
     * the current user.
     * @param   Id        recordTypeId
     * @returns  String
     */
    private static String getRecordTypeDeveloperName(Id recordTypeId) {
        if (recordTypeId == null) {
            for(RecordTypeInfo RTinfo: PJN_Fulfillment_Request__c.SObjectType.getDescribe().getRecordTypeInfos()) {
                if(RTinfo.isAvailable() && RTinfo.isDefaultRecordTypeMapping()) {
                    recordTypeId = RTinfo.getRecordTypeId();
                }
            }
        }
        return [
            SELECT
                Id,
                DeveloperName
            FROM
                RecordType
            WHERE
                Id = :recordTypeId
        ].DeveloperName;
    }

    /**
     * get care plan record with lookups that will be used for the mapping
     * @param   Id        careplanId
     * @returns  Case
     */
    private static Case getCarePlanWithLookupFields(Id careplanId) {
        Set<String> fieldNames = new Set<String>();
        for(PJN_Fulfillment_Request_Creation__mdt thisFulFillmentMapping : fulFillmentMappings) {
            fieldNames.add(thisFulFillmentMapping.PJN_Care_Plan_Source_Field_API_Name__c);
        }

        Case careplan = Database.query(
            'SELECT ' +
                'PJN_Program_DeveloperName__c, ' +
                String.join(new List<String>(fieldNames), ', ') + ' ' +
            'FROM ' +
                'Case ' +
            'WHERE ' +
                'Id = :careplanId'
        );
        return careplan;
    }

    /**
     * create mappings for the mapping engine run
     * @param   Case        careplan
     * @returns  Map<String, Id>
     */
    private static Map<String, Id> createMappings(Case careplan) {
        Map<String, Id> mappings = new Map<String, Id>();
        for(PJN_Fulfillment_Request_Creation__mdt thisFulFillmentMapping : fulFillmentMappings) {
            mappings.put(
                thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c,
                (Id) careplan.get(thisFulFillmentMapping.PJN_Care_Plan_Source_Field_API_Name__c)
            );
            mappings.put(
                thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c + 'labels',
                (Id) careplan.get(thisFulFillmentMapping.PJN_Care_Plan_Source_Field_API_Name__c)
            );
            mappings.put(
                thisFulFillmentMapping.PJN_Mapping_Object_Type_Name__c + 'dates',
                (Id) careplan.get(thisFulFillmentMapping.PJN_Care_Plan_Source_Field_API_Name__c)
            );
        }
        return mappings;
    }

    /**
     * populate fulfillment request with the care plans lookup fields configured in the fulfillment mapping
     * @param   Case                            careplan
     * @param   PJN_Fulfillment_Request__c      fulfillmentRequest
     * @returns  PJN_Fulfillment_Request__c
     */
    private static PJN_Fulfillment_Request__c populateLookupFields(Case careplan, PJN_Fulfillment_Request__c fulfillmentRequest) {
        for(PJN_Fulfillment_Request_Creation__mdt thisFulFillmentMapping : fulFillmentMappings) {
            fulfillmentRequest.put(
                thisFulFillmentMapping.PJN_Request_Target_Field_API_Name__c,
                (Id) careplan.get(thisFulFillmentMapping.PJN_Care_Plan_Source_Field_API_Name__c)
            );
        }
        return fulfillmentRequest;
    }
}