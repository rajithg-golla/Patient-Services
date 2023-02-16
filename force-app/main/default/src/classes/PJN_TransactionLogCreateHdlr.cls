/**
 * Create Transaction Log record on Transaction Log object once Transaction Log event is published
 * @author  Mavens
 * @group   DEBUG
 */
public without sharing class PJN_TransactionLogCreateHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;

        Boolean isAllowed = Trigger.IsAfter && Trigger.IsInsert
            && pjnSetting != null
            && String.isNotBlank(pjnSetting.PJN_Transaction_Log_Level__c)
            && pjnSetting.PJN_Transaction_Log_Level__c.toLowerCase() != 'none';

        if (!isAllowed) {
            return;
        }


        List<PJN_Transaction_Log_Object__c> transactionLogObjs = new List<PJN_Transaction_Log_Object__c>();

        for (PJN_Transaction_Log__e transactionLog : (List<PJN_Transaction_Log__e>) Trigger.new) {
            Boolean isLogAllowed = pjnSetting.PJN_Transaction_Log_Level__c.toLowerCase() == 'all'
                || transactionLog.PJN_Level__c.toLowerCase() == pjnSetting.PJN_Transaction_Log_Level__c.toLowerCase();

            if (!isLogAllowed) {
                continue;
            }

            transactionLogObjs.add(
                new PJN_Transaction_Log_Object__c(
                    PJN_Callout_Request__c = transactionLog.PJN_Callout_Request__c,
                    PJN_Callout_Response__c = transactionLog.PJN_Callout_Response__c,
                    PJN_Incoming_URL__c = transactionLog.PJN_Incoming_URL__c,
                    PJN_Level__c = transactionLog.PJN_Level__c,
                    PJN_Record_Related__c = transactionLog.PJN_Record_Related__c,
                    PJN_Running_User__c = transactionLog.PJN_Running_User__c,
                    PJN_Type__c = transactionLog.PJN_Type__c,
                    PJN_Message__c = transactionLog.PJN_Message__c
                )
            );
        }

        if (!transactionLogObjs.isEmpty()) {
            insert transactionLogObjs;
        }
    }
}