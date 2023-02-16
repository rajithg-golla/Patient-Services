/**
* @author Mavens
* @date May 2019
* @description Test class for PJN_EventHdlr
* @group event-triggers
*/
@isTest(isParallel=true) private class PJN_EventHdlrTest {
    /**
    * @description setups data for all unit tests
    */
    @testSetup private static void setup() {
        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan Case'
        );
        insert carePlan;
    }

    @isTest private static void testCreateTherapyStatusUpdateEventUpdateCarePlan() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id therapyStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                        .get('PJN_Therapy_Status_Update').getRecordTypeId();
        Test.startTest();
            insert new PJN_Event__c(
                RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                            .get('PJN_Therapy_Status_Update').getRecordTypeId(),
                PJN_Case__c = carePlan.Id,
                PJN_New_Therapy_Status__c = 'Cancelled',
                PJN_New_Therapy_Sub_Status__c = 'Patient Deceased'
            );
        Test.stopTest();
        Case thisCarePlan = [
            SELECT
                PJN_Therapy_Status__c,
                PJN_Therapy_Sub_Status__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];
        System.assertEquals('Cancelled',
                            thisCarePlan.PJN_Therapy_Status__c);
        System.assertEquals('Patient Deceased',
                            thisCarePlan.PJN_Therapy_Sub_Status__c);
    }

    @isTest private static void testCreateDifferentEventDoNotUpdateCarePlan() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];

        Test.startTest();
            insert new PJN_Event__c(
                RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                            .get('PJN_Physician_Change').getRecordTypeId(),
                PJN_Case__c = carePlan.Id
            );
        Test.stopTest();
        Case thisCarePlan = [
            SELECT
                PJN_Therapy_Status__c,
                PJN_Therapy_Sub_Status__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];
        System.assertEquals(null, thisCarePlan.PJN_Therapy_Status__c);
        System.assertEquals(null, thisCarePlan.PJN_Therapy_Sub_Status__c);
    }
}