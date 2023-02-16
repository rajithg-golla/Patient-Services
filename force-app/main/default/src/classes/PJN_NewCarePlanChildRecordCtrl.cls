/**
 * @author      Mavens
 * @group       CarePlan
 * @description used by NEW override on care plan children
 */
public with sharing class PJN_NewCarePlanChildRecordCtrl {
    /**
     * mapping engine
     */
    @testVisible private static PJN_MappingEngine sObjectMappingEngine = new PJN_MappingEngine();

    /**
     * populate lookups and run mapping engine to populate all fields as configured
     * @param   Id      carePlanId
     * @param   String  sobjectName
     * @returns  SObject
     */
    @auraEnabled public static SObject getCarePlanChildMapped(Id carePlanId, String sobjectName, String recordTypeId) {
        try {
            SObject theSObject = (SObject) Schema.getGlobalDescribe().get(sobjectName).newSObject();

            if (recordTypeId != null) {
                theSObject.put('RecordTypeId', recordTypeId);
            }

            if (carePlanId == null) {
                return theSObject;
            }

            return getSObjectMapped(carePlanId, theSObject);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * populate lookups and run mapping engine to populate all fields as configured
     * @param   Id          carePlanId
     * @param   SObject     theSObject
     * @returns  SObject
     */
    public static SObject getSObjectMapped(Id carePlanId, SObject theSObject) {
        PJN_Care_Plan_Field_Mapping__mdt carePlanFieldMapping = getCarePlanMappings(theSObject.getSObjectType());

        if (carePlanFieldMapping == null) {
            return theSObject;
        }

        List<Id> carePlanIds = new List<Id> {
            carePlanId
        };

        theSObject.put(
            carePlanFieldMapping.PJN_Care_Plan_Lookup_API_Name__c,
            carePlanId
        );

        if (carePlanFieldMapping.PJN_Id_API_Name__c != 'Id') {
            theSObject.put(
                carePlanFieldMapping.PJN_Id_API_Name__c,
                (theSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c) == null ? PJN_UUIDGenerator.randomUUID() : (String) theSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c))
            );
        }

        List<SObject> sObjectsToBeMapped = new List<SObject> {
            theSObject
        };

        Map<String, List<Id>> sourceObjectIds = new Map<String, List<Id>> {
            'careplan' => carePlanIds,
            'careplanlabels' => carePlanIds,
            'careplandates' => carePlanIds
        };

        Map<String, SObject> mappedSObjects = new Map<String, SObject>();
        sObjectMappingEngine.initiate(carePlanFieldMapping.PJN_Mapping_Job_Name__c);
        sObjectMappingEngine.identifier = carePlanFieldMapping.PJN_Id_API_Name__c;
        mappedSObjects.putAll(
            sObjectMappingEngine.run(
                sourceObjectIds,
                sObjectsToBeMapped
            )
        );

        if(!mappedSObjects.isEmpty()) {
            theSObject = mappedSObjects.get((String) theSObject.get(carePlanFieldMapping.PJN_Id_API_Name__c));
        }

        return theSObject;
    }

    /**
     * get care plan mappings setup
     * @param   SObjectType         thisSObjectType
     * @returns  PJN_Care_Plan_Field_Mapping__mdt
     */
    private static PJN_Care_Plan_Field_Mapping__mdt getCarePlanMappings(SObjectType thisSObjectType) {
        List<PJN_Care_Plan_Field_Mapping__mdt> carePlanMappings = [
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

        if (carePlanMappings == null || carePlanMappings.isEmpty()) {
            return null;
        }

        return carePlanMappings[0];
    }
}