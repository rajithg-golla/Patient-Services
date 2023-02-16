/**
 * @author      Mavens
 * @group       Log
 * @description handle log event and create PJN_Log__c records
 */
public without sharing class PJN_LogEventSubscriber implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handle after insert trigger context
     */
    public void handle() {
        List<PJN_Log__c> logsToInsert = new List<PJN_Log__c>();
        for(PJN_Log_Event__e thisLogEvent : (List<PJN_Log_Event__e>) trigger.new) {
            logsToInsert.add(
                new PJN_Log__c(
                    PJN_Source__c = thisLogEvent.PJN_Source__c,
                    PJN_Message__c = thisLogEvent.PJN_Message__c,
                    PJN_Exception_Type__c = thisLogEvent.PJN_Exception_Type__c,
                    PJN_Exception_JSON__c = thisLogEvent.PJN_Exception_JSON__c,
                    PJN_SObject_Type__c = thisLogEvent.PJN_SObject_Type__c,
                    PJN_SObject_JSON__c = thisLogEvent.PJN_SObject_JSON__c
                )
            );
        }
        insert logsToInsert;
    }
}