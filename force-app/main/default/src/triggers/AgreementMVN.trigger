trigger AgreementMVN on echosign_dev1__SIGN_Agreement__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}