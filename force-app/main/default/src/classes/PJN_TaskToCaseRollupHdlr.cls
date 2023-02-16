/**
 * @author      Mavens
 * @date        January 2021
 * @description Trigger hanlder to count the number of contact attempts on a case and also set the date of the latest
 * @group       Task
 */
public with sharing class PJN_TaskToCaseRollupHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {

        Set<Id> caseIds = new Set<Id>();
        Id callAttemptRecTypeId = SObjectType.Task
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Contact_Attempt')
            .getRecordTypeId();

        List<Task> scope;
        if (Trigger.isDelete) {
            scope = (List<Task>) Trigger.old;
        } else {
            scope = (List<Task>) Trigger.new;
        }

        for (Task task : scope) {
            if (task.WhatId != null
                && task.WhatId.getSobjectType() == Case.getSObjectType()
                && task.RecordTypeId == callAttemptRecTypeId) {

                caseIds.add(task.WhatId);
            }
        }

        if (caseIds.isEmpty()) {
            return;
        }

        List<Case> cases = [
            SELECT Id,
                PJN_Most_Recent_Call_Attempt2__c,
                PJN_Number_of_Attempts2__c,
                (
                    SELECT PJN_Attempt_Date_Time__c
                    FROM Tasks
                    WHERE RecordType.DeveloperName = 'PJN_Contact_Attempt'
                    ORDER BY PJN_Attempt_Date_Time__c DESC NULLS LAST
                )
            FROM Case
            WHERE Id IN :caseIds
        ];

        for (Case currentCase : cases) {
            currentCase.PJN_Number_of_Attempts2__c = currentCase.Tasks.size();
            if (currentCase.Tasks.size() > 0) {
                currentCase.PJN_Most_Recent_Call_Attempt2__c = currentCase.Tasks.get(0).PJN_Attempt_Date_Time__c;
            } else {
                currentCase.PJN_Most_Recent_Call_Attempt2__c = null;
            }
        }

        update cases;
    }
}