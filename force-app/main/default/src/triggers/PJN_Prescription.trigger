trigger PJN_Prescription on HealthCloudGA__EhrMedicationPrescription__c(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}