trigger PJN_NetworkEventMVN on PJN_Veeva_Network__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}