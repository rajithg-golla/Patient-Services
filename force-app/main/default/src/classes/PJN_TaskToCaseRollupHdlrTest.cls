/**
 * @author      Mavens
 * @date        January 2021
 * @description Unit tests for PJN_TaskToCaseRollupHdlr
 * @group       Task
 */
@isTest
public class PJN_TaskToCaseRollupHdlrTest {

    private static Id callAttemptRecTypeId;

    static {
        setupTriggerHandlers();

        callAttemptRecTypeId = SObjectType.Task
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Contact_Attempt')
            .getRecordTypeId();
    }

    @TestSetup
    static void makeData(){

        Id activityRecordTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Activity')
            .getRecordTypeId();

        List<Case> cases = new List<Case> {
            new Case(RecordTypeId = activityRecordTypeId),
            new Case(RecordTypeId = activityRecordTypeId)
        };

        insert cases;
    }

    @isTest
    private static void itShouldSetRollupsOnInsert() {
        List<Task> tasks = setupTasks();

        Test.startTest();
        insert tasks;
        Test.stopTest();

        System.assertEquals(2, [
            SELECT COUNT()
            FROM Case
            WHERE PJN_Most_Recent_Call_Attempt2__c = :Date.today()
            AND PJN_Number_of_Attempts2__c = 100
        ]);
    }

    @isTest
    private static void itShouldSetRollupsOnDelete() {

        List<Task> tasks = setupTasks();
        insert tasks;

        Test.startTest();
        delete Tasks;
        Test.stopTest();

        System.assertEquals(2, [
            SELECT COUNT()
            FROM Case
            WHERE PJN_Most_Recent_Call_Attempt2__c = null
            AND PJN_Number_of_Attempts2__c = 0
        ]);
    }

    @isTest
    private static void itShouldReturnFromExecutionWhenNoCallAttemptsOnCase() {
        // Ensure the return statement, when there are no case ids, is executed

        Test.startTest();
        insert new Task(
            Status = 'Completed'
        );
        Test.stopTest();
    }

    private static void setupTriggerHandlers() {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            Task.getSobjectType(), new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(PJN_Class__c = 'PJN_TaskToCaseRollupHdlr', PJN_Event__c = 'AFTER_INSERT'),
                new PJN_Trigger_Handler_Setting__mdt(PJN_Class__c = 'PJN_TaskToCaseRollupHdlr', PJN_Event__c = 'AFTER_UPDATE'),
                new PJN_Trigger_Handler_Setting__mdt(PJN_Class__c = 'PJN_TaskToCaseRollupHdlr', PJN_Event__c = 'AFTER_DELETE'),
                new PJN_Trigger_Handler_Setting__mdt(PJN_Class__c = 'PJN_TaskToCaseRollupHdlr', PJN_Event__c = 'AFTER_UNDELETE')
            }
        );
    }

    private static List<Task> setupTasks() {
        List<Case> cases = [SELECT Id FROM Case];
        List<Task> tasks = new List<Task>();

        for (Integer i=0; i<100; i++) {
            tasks.add(
                new Task(
                    WhatId = cases.get(0).Id,
                    PJN_Attempt_Date_Time__c = Date.today().addDays(-1 * i),
                    Status = 'Completed',
                    RecordTypeId = callAttemptRecTypeId
                )
            );
            tasks.add(
                new Task(
                    WhatId = cases.get(1).Id,
                    PJN_Attempt_Date_Time__c = Date.today().addDays(-1 * i),
                    Status = 'Completed',
                    RecordTypeId = callAttemptRecTypeId
                )
            );
        }

        return tasks;
    }


}