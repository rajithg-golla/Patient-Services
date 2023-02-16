trigger PJN_FulfillmentRequest on PJN_Fulfillment_Request__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}