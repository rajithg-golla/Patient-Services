/**
 * @author Mavens
 * @date May 2019
 * @description Creates an Event if the physician lookup on the Care Plan is updated
 * @group event-triggers
 */
public with sharing class PJN_EventCreation implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * Handle the trigger call
     */
    public void handle() {
        Set<Id> caseIds = new Set<Id>();
        for (Case currentCase : (List<Case>)Trigger.new) {
            if (this.isPhysicianUpdated(currentCase.Id)) {
                caseIds.add(currentCase.Id);
            }
        }
        createEvents(caseIds);
    }
    /**
     * Checks if the Physician lookup field has been updated for a care plan case
     * @param  caseId case id
     * @returns Boolean
     */
    private Boolean isPhysicianUpdated(Id caseId) {
        Case oldCase = (Case) Trigger.oldMap.get(caseId);
        Case newCase = (Case) Trigger.newMap.get(caseId);
        if (newCase.RecordTypeId == SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
            && oldCase.PJN_Physician__c != newCase.PJN_Physician__c) {
            return true;
        }
        return false;
    }

    /**
     * Create Event records with record type Physician Change
     * @param  caseIds case Ids to create the events against
     */
    private void createEvents(Set<Id> caseIds) {
        List<PJN_Event__c> events = new List<PJN_Event__c>();
        if (!caseIds.isEmpty()) {
            for (Id caseId : caseIds) {
                Case oldCase = (Case) Trigger.oldMap.get(caseId);
                Case newCase = (Case) Trigger.newMap.get(caseId);
                events.add(
                    new PJN_Event__c(
                        RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('PJN_Physician_Change').getRecordTypeId(),
                        PJN_Patient__c = newCase.AccountId,
                        PJN_Case__c = newCase.Id,
                        PJN_New_Physician__c = newCase.PJN_Physician__c,
                        PJN_Previous_Physician__c = oldCase.PJN_Physician__c
                    )
                );
            }
            insert events;
        }
    }
}