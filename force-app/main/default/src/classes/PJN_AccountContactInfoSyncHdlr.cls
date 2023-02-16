/**
 *  Trigger handler used to keep contact information in sync with
 *  account data. Metadata configuration will allow for mapping
 *  of account fields to proper contact info record types.
 *  Should be called after insert/update/undelete.
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_AccountContactInfoSyncHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        Boolean isAllowed = Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete);

        if (!isAllowed) {
            return;
        }

        PJN_ObjectFieldContactInfoSync objectFieldContactInfoSync = new PJN_ObjectFieldContactInfoSync();
        objectFieldContactInfoSync.oldRecordsMap = !Trigger.isInsert ? Trigger.oldMap : null;
        objectFieldContactInfoSync.syncContactInfoFromObject(Trigger.new);
    }
}