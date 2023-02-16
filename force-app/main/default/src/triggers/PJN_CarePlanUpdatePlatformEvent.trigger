trigger PJN_CarePlanUpdatePlatformEvent on PJN_Care_Plan_Update__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}