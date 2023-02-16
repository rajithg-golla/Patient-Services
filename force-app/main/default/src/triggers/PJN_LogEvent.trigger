trigger PJN_LogEvent on PJN_Log_Event__e(after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}