/**
 * @author      Mavens
 * @date        04/2021
 * @description Unit tests for PJN_RecurringCaseHdlr
 * @group       Case
 */
@isTest
public class PJN_RecurringCaseHdlrTest {

    static {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> {
            SObjectType.Case.getSObjectType() => new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PJN_RecurringCaseHdlr',
                    PJN_Event__c = 'AFTER_INSERT',
                    PJN_SObject_API_Name__c = 'Case'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PJN_RecurringCaseHdlr',
                    PJN_Event__c = 'AFTER_UPDATE',
                    PJN_SObject_API_Name__c = 'Case'
                )
            }
        };
    }
    @isTest
    private static void itShouldCloneRecurringCaseOnCloseOnUpdate() {
        List<Case> cases = new List<Case>();
        for (Integer i=0; i<200; i++) {
            cases.add(
                new Case(
                    PJN_Repeat__c = 'Repeats',
                    Subject = 'Recurring Test',
                    Description = 'A test case for recurring',
                    PJN_Repeat_Every__c = 60,
                    PJN_Cadence__c = 'Day',
                    HealthCloudGA__DueDate__c = Date.today()
                )
            );
        }
        insert cases;
        for (Case c : cases) {
            c.Status = 'Closed';
        }
        Test.startTest();
        update cases;
        Test.stopTest();
        System.assertEquals(200, [
            SELECT COUNT()
            FROM Case
            WHERE isClosed = true
        ], 'Expected 200 closed cases');
        System.assertEquals(200, [
            SELECT COUNT()
            FROM Case
            WHERE isClosed = false
            AND (
                HealthCloudGA__DueDate__c = :Date.today().addDays(60)
                OR HealthCloudGA__DueDate__c = :Date.today().addDays(59)
                OR HealthCloudGA__DueDate__c = :Date.today().addDays(61)
            )
        ], 'Expected 200 open cases with due date 60 days away');
    }
    @isTest
    private static void itShouldCloneRecurringCaseOnCloseAtInsert() {
        List<Case> cases = new List<Case>();
        for (Integer i=0; i<200; i++) {
            cases.add(
                new Case(
                    PJN_Repeat__c = 'Repeats',
                    Subject = 'Recurring Test',
                    Description = 'A test case for recurring',
                    PJN_Repeat_Every__c = 60,
                    PJN_Cadence__c = 'Day',
                    HealthCloudGA__DueDate__c = Date.today(),
                    Status = 'Closed'
                )
            );
        }
        Test.startTest();
        insert cases;
        Test.stopTest();
        System.assertEquals(200, [
            SELECT COUNT()
            FROM Case
            WHERE isClosed = true
        ], 'Expected 200 closed cases');
        System.assertEquals(200, [
            SELECT COUNT()
            FROM Case
            WHERE isClosed = false
            AND (
                HealthCloudGA__DueDate__c = :Date.today().addDays(60)
                OR HealthCloudGA__DueDate__c = :Date.today().addDays(59)
                OR HealthCloudGA__DueDate__c = :Date.today().addDays(61)
            )
        ], 'Expected 200 open cases with due date 60 days away');
    }
}