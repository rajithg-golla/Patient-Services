/**
 * DCR trigger handler to update records related
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRUpdateRecord implements PJN_TriggerDispatcher.HandlerInterface {

    private static Boolean hasRun = false;
    private static Map<Id, Set<Id>> dcrIdsByRecordId;
    private static Map<Id, PJN_Data_Change_Request__c> dcrsById;
    private static Map<String, Map<Id, SObject>> recordsMapBySObject;

    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.isAfter && Trigger.isUpdate && !hasRun;

        if(!isAllowed) {
            return;
        }

        initDCRsAndRecordsRelated();

        List<SObject> recordsToUpdate = new List<SObject>();

        for (String sobjectName : recordsMapBySObject.keySet()) {
            if (recordsMapBySObject.get(sobjectName) == null) {
                continue;
            }

            recordsToUpdate.addAll(recordsMapBySObject.get(sobjectName).values());
        }

        if (recordsToUpdate.isEmpty()) {
            return;
        }

        PJN_DCR.updateFromNetwork = true;
        hasRun = true;
        List<Database.SaveResult> saveResults = Database.update(recordsToUpdate);
        List<PJN_Data_Change_Request__c> dcrsToUpdate = new List<PJN_Data_Change_Request__c>();

        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess()) {
                Set<Id> dcrIds = dcrIdsByRecordId.get(saveResult.getId());

                if (dcrIds == null || dcrIds.isEmpty()) {
                    continue;
                }

                for (Id dcrId : dcrIds) {
                    PJN_Data_Change_Request__c dcr = dcrsById.get(dcrId);

                    if (dcr == null) {
                        continue;
                    }

                    dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_UPDATED;
                    dcrsToUpdate.add(dcr);
                }
            } else {
                System.debug('DCR Id error: ' + saveResult.getId());
                System.debug('Error msg: ' + saveResult.getErrors()[0]);
            }
        }

        PJN_DCR.updateFromNetwork = true;
        update dcrsToUpdate;
        PJN_DCR.updateFromNetwork = false;
    }

    private static void initDCRsAndRecordsRelated() {
        dcrIdsByRecordId = new Map<Id, Set<Id>>();
        recordsMapBySObject = new Map<String, Map<Id, SObject>>();
        Map<Id, Datetime> createdDateById = new Map<Id, Datetime>();
        Map<Id, SObject> recordsById = new Map<Id, SObject>();

        dcrsById = getDCRsProcessedWithLines();

        for (PJN_Data_Change_Request__c dcr : dcrsById.values()) {
            SObject record;

            if (dcr.PJN_Account__c != null) {
                record = new Account (
                    Id = dcr.PJN_Account__c,
                    PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                );
            } else if (dcr.PJN_Contact_Information__c != null) {
                record = new PJN_Contact_Information__c (
                    Id = dcr.PJN_Contact_Information__c,
                    PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                );
            } else if (dcr.PJN_License__c != null) {
                record = new PJN_License__c (
                    Id = dcr.PJN_License__c,
                    PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                );

                if (dcr.PJN_License_Address__c != null) {
                    record.put('PJN_Contact_Information__c', dcr.PJN_License_Address__c);
                }
            }

            if (!recordsById.containsKey(record.Id)) {
                recordsById.put(record.Id, record);
            }
            if (!createdDateById.containsKey(record.Id) || createdDateById.get(record.Id) > dcr.createddate) {
                createdDateById.put(record.Id, dcr.createddate);
            }

            String objectName = record.Id.getSObjectType().getDescribe().getName();
            SObject storedRecord = recordsById.get(record.Id);
            Datetime lastCreatedDate = createdDateById.get(record.Id);
            Map<String, Object> fieldsToValue = storedRecord.getPopulatedFieldsAsMap();
            for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                if (!fieldsToValue.containsKey(dcrLine.PJN_Field_API_Name__c) || dcr.CreatedDate >= lastCreatedDate) {
                    storedRecord.put(
                        dcrLine.PJN_Field_API_Name__c,
                        getFieldValueWithFieldType(objectName, dcrLine.PJN_Field_API_Name__c, dcrLine.PJN_Final_Value__c)
                    );
                }
            }

            Map<Id, SObject> currentRecords = recordsMapBySObject.containsKey(objectName) ?
                                            recordsMapBySObject.get(objectName) : new Map<Id, SObject>();
            currentRecords.put(record.Id, storedRecord);
            recordsMapBySObject.put(objectName, currentRecords);

            Set<Id> dcrIds = dcrIdsByRecordId.containsKey(record.Id) ?
                            dcrIdsByRecordId.get(record.Id) : new Set<Id>();

            dcrIds.add(dcr.Id);
            dcrIdsByRecordId.put(record.Id, dcrIds);
        }
    }

    private static Object getFieldValueWithFieldType(String sobjectName, String fieldName, String fieldValue) {
        if (String.isBlank(sobjectName) || String.isBlank(fieldName) || String.isBlank(fieldValue)) {
            return fieldValue;
        }
        Object fieldValueObject = fieldValue;

        Schema.DisplayType fieldType = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
        if(fieldType == Schema.DisplayType.DATE) {
            fieldValueObject = Date.valueOf(fieldValue);
        } else if(fieldType == Schema.DisplayType.DATETIME) {
            fieldValueObject = Datetime.valueOf(fieldValue);
        } else if (fieldType == Schema.DisplayType.BOOLEAN) {
            fieldValueObject = Boolean.valueOf(fieldValue);
        }

        return fieldValueObject;
    }

    private static Map<Id, PJN_Data_Change_Request__c> getDCRsProcessedWithLines() {
        Set<Id> dcrIdsToUpdateRecords = new Set<Id>();

        for (PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {
            if (dcr.PJN_Status__c != PJN_NetworkConstants.DCR_STATUS_PROCESSED) {
                continue;
            }

            dcrIdsToUpdateRecords.add(dcr.Id);
        }

        return new Map<Id, PJN_Data_Change_Request__c>(PJN_DCRQuery.queryWithLinesByIds(dcrIdsToUpdateRecords));
    }
}