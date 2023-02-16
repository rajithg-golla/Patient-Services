/**
 * @author      Mavens
 * @date        11/2020
 * @description Trigger for coverage investigation records
 * @group       CoverageInvestigation
 */
trigger PJN_CoverageInvestigation on PJN_Coverage_Investigation__c (
    before insert, after insert, before update, after update, before delete, after delete, after undelete
) {
    new PJN_TriggerDispatcher().addTriggerHandlerSettingRecords().dispatch();
}