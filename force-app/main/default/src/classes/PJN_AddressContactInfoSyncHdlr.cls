/**
 *  Trigger handler used to keep contact information in sync with
 *  address data. Metadata configuration will allow for mapping
 *  of address fields to proper contact info record types.
 *  Should be called after insert/update/undelete.
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_AddressContactInfoSyncHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        Boolean isAllowed = Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete);

        if (!isAllowed) {
            return;
        }

        PJN_ObjectFieldContactInfoSync objectFieldContactInfoSync = new PJN_ObjectFieldContactInfoSync();
        objectFieldContactInfoSync.oldRecordsMap = !Trigger.isInsert ? Trigger.oldMap : null;
        objectFieldContactInfoSync.accountFieldName = 'PJN_Account__c';
        objectFieldContactInfoSync.relatedRecordFieldName = 'PJN_Created_From_Address__c';

        List<PJN_Contact_Information__c> contactInfos = new List<PJN_Contact_Information__c>();
        Id addressRecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId();

        for (PJN_Contact_Information__c contactInfo : (List<PJN_Contact_Information__c>) Trigger.new) {
            if (contactInfo.RecordTypeId == addressRecordTypeId) {
                contactInfos.add(contactInfo);
            }
        }

        objectFieldContactInfoSync.syncContactInfoFromObject(contactInfos);
    }
}