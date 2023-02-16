/**
 * @author Mavens
 * @date May 2019
 * @description On therapy status update event creation, update care plan with new therapy status/sub-status values
 * @group event-triggers
 */
public with sharing class PJN_EventHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * Handle the trigger call
     */
    public void handle() {
        Map<Id, Case> carePlanMap = new Map<Id, Case>();
        for (PJN_Event__c event : (List<PJN_Event__c>)Trigger.new) {
            Id therapyStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                        .get('PJN_Therapy_Status_Update').getRecordTypeId();
            if (event.RecordTypeId == therapyStatusUpdateRT) {
                carePlanMap.put(
                    event.PJN_Case__c,
                    new Case(
                        Id = event.PJN_Case__c,
                        PJN_Therapy_Status__c = event.PJN_New_Therapy_Status__c,
                        PJN_Therapy_Sub_Status__c = event.PJN_New_Therapy_Sub_Status__c
                    )
                );
            }
        }
        update carePlanMap.values();
    }
}