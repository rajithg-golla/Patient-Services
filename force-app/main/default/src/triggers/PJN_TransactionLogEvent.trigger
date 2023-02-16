trigger PJN_TransactionLogEvent on PJN_Transaction_Log__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}