/**
 *  Trigger handler used to keep contact information in sync with
 *  address data. Metadata configuration will allow for mapping
 *  of address fields to proper contact info record types.
 *  Should be called after insert/update/undelete.
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_ContactInfoMappingSyncHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        Boolean isAllowed = Trigger.isAfter && (Trigger.isUpdate || Trigger.isUndelete);

        if (!isAllowed) {
            return;
        }

        PJN_ObjectFieldContactInfoSync objectFieldContactInfoSync = new PJN_ObjectFieldContactInfoSync();
        objectFieldContactInfoSync.oldRecordsMap = Trigger.oldMap;
        objectFieldContactInfoSync.syncContactInfoToObject((List<PJN_Contact_Information__c>) Trigger.new);
    }
}