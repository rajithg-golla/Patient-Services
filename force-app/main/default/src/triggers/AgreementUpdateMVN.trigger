trigger AgreementUpdateMVN on Agreement_Update_MVN__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}