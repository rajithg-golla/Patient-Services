trigger PJN_ContactPointTypeConsent on PJN_Contact_Point_Type_Consent__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}