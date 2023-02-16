trigger PendingLeadMVN on Pending_Lead_MVN__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}