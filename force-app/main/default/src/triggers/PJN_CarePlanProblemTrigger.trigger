trigger PJN_CarePlanProblemTrigger on HealthCloudGA__CarePlanProblem__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}