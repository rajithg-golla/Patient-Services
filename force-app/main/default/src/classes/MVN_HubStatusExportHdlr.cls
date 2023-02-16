/**
 * @author Mavens
 * @description On therapy status update event creation, set fields below following IntegriChain pattern
 *                  - MVN_Status_Description__c
 *                  - MVN_Milestone__c
 *                  - MVN_Status_Code__c
 * @group hub-status-export
 */
public with sharing class MVN_HubStatusExportHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * Handle the trigger call BEFORE INSERT
     */
    public void handle() {
        Id therapyStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId();
        Id therapyStatusRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('MVN_Therapy_Status_Restatement').getRecordTypeId();
                                    
        Map<PJN_Event__c, PJN_Event__c> eventsCloned = new Map<PJN_Event__c,PJN_Event__c>();
        for (PJN_Event__c event : (List<PJN_Event__c>)Trigger.new) {
            if (event.RecordTypeId == therapyStatusUpdateRT || event.RecordTypeId == therapyStatusRT) {
                eventsCloned.put(event, event.clone());
            }
        }
        Formula.recalculateFormulas(eventsCloned.values());
        for (PJN_Event__c event : (List<PJN_Event__c>)Trigger.new) {
            if (event.RecordTypeId == therapyStatusUpdateRT || event.RecordTypeId == therapyStatusRT) {
                PJN_Event__c eventCloned = eventsCloned.get(event);
                event.MVN_Status_Description__c =
                    (eventCloned.MVN_Status_Description_Active__c != null ? eventCloned.MVN_Status_Description_Active__c :
                    (eventCloned.MVN_Status_Description_Pending__c != null ? eventCloned.MVN_Status_Description_Pending__c :
                    (eventCloned.MVN_Status_Description_Cancelled__c != null ? eventCloned.MVN_Status_Description_Cancelled__c :
                    (eventCloned.MVN_Status_Description_Discontinued__c != null ? eventCloned.MVN_Status_Description_Discontinued__c :
                    ''))));
                event.MVN_Milestone__c =
                    (eventCloned.MVN_Milestone_Active__c != null ? eventCloned.MVN_Milestone_Active__c :
                    (eventCloned.MVN_Milestone_Pending__c != null ? eventCloned.MVN_Milestone_Pending__c :
                    (eventCloned.MVN_Milestone_Cancelled__c != null ? eventCloned.MVN_Milestone_Cancelled__c :
                    (eventCloned.MVN_Milestone_Discontinued__c != null ? eventCloned.MVN_Milestone_Discontinued__c :
                    ''))));
                event.MVN_Status_Code__c =
                    (eventCloned.MVN_Status_Code_Active__c != null ? eventCloned.MVN_Status_Code_Active__c :
                    (eventCloned.MVN_Status_Code_Pending__c != null ? eventCloned.MVN_Status_Code_Pending__c :
                    (eventCloned.MVN_Status_Code_Cancelled__c != null ? eventCloned.MVN_Status_Code_Cancelled__c :
                    (eventCloned.MVN_Status_Code_Discontinued__c != null ? eventCloned.MVN_Status_Code_Discontinued__c :
                    ''))));
            }
        }
    }
}