/**
 * This class syncs Objects to/from Contact Information using PJN_Object_Field_Contact_Info_Mapping__mdt metadata
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_ObjectFieldContactInfoSync {

    private static Boolean objectToContactInfoRun = false;
    private static Boolean contactInfoToObjectRun = false;

    /**
     * Old records from Trigger
     */
    public Map<Id, SObject> oldRecordsMap;

    /**
     * Account Id field in the Object.
     * Id if null
     */
    public String accountFieldName;

    /**
     * Object Id field in the Contact Information record
     */
    public String relatedRecordFieldName;

    /**
     * Sync Object to Contact Information
     * @param records   New Records from Trigger
     */
    public void syncContactInfoFromObject(List<SObject> records) {
        if (contactInfoToObjectRun || records == null || records.isEmpty()) {
            return;
        }

        String sobjectName = records[0].Id.getSObjectType().getDescribe().getName();

        List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings = PJN_ObjectFieldContactInfoMappings.getObjectFieldContactInfoMappingByObjectName(sobjectName);

        if (objectFieldContactInfoMappings.isEmpty()) {
            return;
        }

        List<PJN_Contact_Information__c> contactInfos = getContactInformationToUpsert(records, objectFieldContactInfoMappings);

        Boolean isUpdateFromNetwork = PJN_DCR.updateFromNetwork ? true : false;
        PJN_DCR.updateFromNetwork = true;
        objectToContactInfoRun = true;
        Database.UpsertResult[] contactInfoUpsertResults = Database.upsert(
            contactInfos,
            PJN_Contact_Information__c.fields.PJN_External_Id__c,
            false
        );
        objectToContactInfoRun = false;
        PJN_DCR.updateFromNetwork = isUpdateFromNetwork;

        for (Integer index = 0; index < contactInfoUpsertResults.size(); index++) {
            Database.UpsertResult thisContactInfoUpsertResult = contactInfoUpsertResults.get(index);
            PJN_Contact_Information__c thisContactInfo = contactInfos.get(index);
            if(!thisContactInfoUpsertResult.isSuccess()) {
                System.debug('PJN::syncContactInfoFromObject - ' + thisContactInfoUpsertResult.getErrors()[0].getMessage());
                PJN_LogEventHdlr.publishLogEvent(
                    PJN_ObjectFieldContactInfoSync.class.getName(),
                    'Unsuccessful Contact Information upsert for *** ' + thisContactInfo,
                    thisContactInfoUpsertResult,
                    thisContactInfo
                );
            }
        }
    }

    /**
     * Sync Contact Information to SObject
     * @param contactInfos  List of Contact Informations to sync
     */
    public void syncContactInfoToObject(List<PJN_Contact_Information__c> contactInfos) {
        if (objectToContactInfoRun || contactInfos == null || contactInfos.isEmpty() || oldRecordsMap == null || oldRecordsMap.isEmpty()) {
            return;
        }

        Map<String, Map<Id, SObject>> recordsByObjectName = new Map<String, Map<Id, SObject>>();

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            Boolean isAllowed = String.isNotBlank(contactInfo.PJN_External_Id__c)
                && contactInfo.PJN_External_Id__c.contains('-');

            if (!isAllowed) {
                continue;
            }
            String recordId = contactInfo.PJN_External_Id__c.split('-', 2)[0];

            if (!(recordId instanceOf Id)) {
                continue;
            }

            String sobjectName = ((Id) recordId).getSObjectType().getDescribe().getName();

            Map<Id, SObject> currentRecords = recordsByObjectName.containsKey(sobjectName) ?
                recordsByObjectName.get(sobjectName) :
                new Map<Id, SObject>();

            SObject currentRecord = getObjectFromContactInfo(contactInfo, currentRecords);

            if (currentRecord == null) {
                continue;
            }

            currentRecords.put(currentRecord.Id, currentRecord);
            recordsByObjectName.put(sobjectName, currentRecords);
        }

        List<SObject> allRecordsToUpdate = new List<SObject>();

        for (String sobjectName : recordsByObjectName.keySet()) {
            allRecordsToUpdate.addAll(recordsByObjectName.get(sobjectName).values());
        }

        Boolean isUpdateFromNetwork = PJN_DCR.updateFromNetwork ? true : false;
        PJN_DCR.updateFromNetwork = false;
        contactInfoToObjectRun = true;
        List<Database.SaveResult> saveResults = Database.update(allRecordsToUpdate, false);
        contactInfoToObjectRun = false;
        PJN_DCR.updateFromNetwork = isUpdateFromNetwork;

        for (Integer index = 0; index < saveResults.size(); index++) {
            Database.SaveResult saveResult = saveResults.get(index);
            SObject currentRecord = allRecordsToUpdate.get(index);
            if(!saveResult.isSuccess()) {
                System.debug('PJN::syncContactInfoFromObject - ' + saveResult.getErrors()[0].getMessage());
                PJN_LogEventHdlr.publishLogEvent(
                    PJN_ObjectFieldContactInfoSync.class.getName(),
                    'Unsuccessful Record update for *** ' + currentRecord,
                    saveResult,
                    currentRecord
                );
            }
        }
    }

    /**
     * Builds and get Contact Informations created from Object synced
     * @param records                           New Records from Trigger
     * @param objectFieldContactInfoMappings    List of PJN_Object_Field_Contact_Info_Mapping__mdt metadatas specific for the current SObject
     * @return  `List<PJN_Contact_Information__c>`
     */
    private List<PJN_Contact_Information__c> getContactInformationToUpsert(List<SObject> records, List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings) {
        List<PJN_Contact_Information__c> contactInfos = new List<PJN_Contact_Information__c>();

        for (SObject record : records) {
            SObject oldRecord = oldRecordsMap != null && !oldRecordsMap.isEmpty() ?
                oldRecordsMap.get(record.Id) :
                null;

            for (PJN_Object_Field_Contact_Info_Mapping__mdt objectFieldContactInfoMapping : objectFieldContactInfoMappings) {
                Boolean hasChanged = (oldRecord == null && record.get(objectFieldContactInfoMapping.PJN_Field_Name__c) != null)
                    || (oldRecord != null && oldRecord.get(objectFieldContactInfoMapping.PJN_Field_Name__c) != record.get(objectFieldContactInfoMapping.PJN_Field_Name__c));

                if (hasChanged) {
                    PJN_Contact_Information__c currentCI = new PJN_Contact_Information__c(
                        PJN_Account__c = String.isNotBlank(accountFieldName) ? (Id) record.get(accountFieldName) : record.Id,
                        RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get(objectFieldContactInfoMapping.PJN_Contact_Info_Record_Type__c).getRecordTypeId(),
                        PJN_Type__c = objectFieldContactInfoMapping.PJN_Contact_Info_Type__c,
                        PJN_External_Id__c = getObjectFieldContactInfoKey(record.Id, objectFieldContactInfoMapping.PJN_Field_Name__c)
                    );

                    if (String.isNotBlank(relatedRecordFieldName)) {
                        currentCI.put(relatedRecordFieldName, record.Id);
                    }

                    currentCI.put(objectFieldContactInfoMapping.PJN_Contact_Info_Field_Name__c, record.get(objectFieldContactInfoMapping.PJN_Field_Name__c));
                    contactInfos.add(currentCI);
                }
            }
        }

        return contactInfos;
    }

    /**
     * Get SObject record from Contact Information using External Id and ObjectFieldContactInfoMapping metadata
     * @param contactInfo       Contact Information record
     * @param currentRecords    SObject By Id Map
     * @return  `SObject`
     */
    private SObject getObjectFromContactInfo(PJN_Contact_Information__c contactInfo, Map<Id, SObject> currentRecords) {
        String recordId = contactInfo.PJN_External_Id__c.split('-', 2)[0];

        if (!(recordId instanceOf Id)) {
            return null;
        }

        String sobjectName = ((Id) recordId).getSObjectType().getDescribe().getName();

        List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings = PJN_ObjectFieldContactInfoMappings.getObjectFieldContactInfoMappingByObjectName(sobjectName);

        if (objectFieldContactInfoMappings.isEmpty()) {
            return null;
        }

        Boolean hasAnyValueUpdated = false;
        SObject currentRecord = currentRecords.containsKey((Id) recordId) ?
            currentRecords.get((Id) recordId) :
            Schema.getGlobalDescribe().get(sobjectName).newSObject();
        currentRecord.Id = recordId;

        PJN_Contact_Information__c oldContactInfo = (PJN_Contact_Information__c) oldRecordsMap.get(contactInfo.Id);

        for (PJN_Object_Field_Contact_Info_Mapping__mdt objectFieldContactInfoMapping : objectFieldContactInfoMappings) {
            String currentRecordTypeName = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosById().get(contactInfo.RecordTypeId).getDeveloperName();
            Boolean isMappingAllowed = currentRecordTypeName.toLowerCase() == objectFieldContactInfoMapping.PJN_Contact_Info_Record_Type__c.toLowerCase()
                && oldContactInfo.get(objectFieldContactInfoMapping.PJN_Contact_Info_Field_Name__c) != contactInfo.get(objectFieldContactInfoMapping.PJN_Contact_Info_Field_Name__c);

            if (!isMappingAllowed) {
                continue;
            }

            currentRecord.put(objectFieldContactInfoMapping.PJN_Field_Name__c, contactInfo.get(objectFieldContactInfoMapping.PJN_Contact_Info_Field_Name__c));
            hasAnyValueUpdated = true;
        }

        if (!hasAnyValueUpdated) {
            return null;
        }

        return currentRecord;
    }

    /**
     * Builds and get Contact Info External Id
     * @param recordId      SObject record Id
     * @param fieldName     SObject field name
     * @return  `String`
     */
    public static String getObjectFieldContactInfoKey(Id recordId, String fieldName) {
        return recordId + '-' + fieldName;
    }
}