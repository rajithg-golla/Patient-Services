trigger PJN_ProgramEvent on PJN_Program_Event__e (after insert) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}