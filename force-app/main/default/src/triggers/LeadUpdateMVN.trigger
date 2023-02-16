trigger LeadUpdateMVN on Lead_Update_MVN__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}