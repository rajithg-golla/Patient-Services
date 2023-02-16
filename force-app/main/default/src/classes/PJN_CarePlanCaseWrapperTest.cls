/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanCaseWrapper
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanCaseWrapperTest {
    @isTest private static void constructWrapperWithOpenCase() {
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
            Status = 'Open',
            Subject = 'Activity Case'
        );
        insert expectedCase;
        expectedCase = [SELECT Id, PJN_Activity_Timeline_Status__c FROM Case WHERE Id =:expectedCase.Id];

        expectedCase = [SELECT Id, IsClosed, PJN_Activity_Timeline_Status__c FROM Case WHERE Id = :expectedCase.Id];
        Test.startTest();
            PJN_CarePlanCaseWrapper actualCarePlanCaseWrapper = new PJN_CarePlanCaseWrapper(expectedCase);
        Test.stopTest();

        System.assertEquals(expectedCase.Id, actualCarePlanCaseWrapper.caseRecord.Id, 'case record does not match');
        System.assertEquals('open', actualCarePlanCaseWrapper.activityType, 'activity type is not set correctly');
        System.assertEquals(null, actualCarePlanCaseWrapper.programCase, 'program case should be null');
    }

    @isTest private static void constructWrapperWithClosedCase() {
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
            Status = 'Closed',
            Subject = 'Activity Case'
        );
        insert expectedCase;
        expectedCase = [SELECT Id, IsClosed, PJN_Activity_Timeline_Status__c FROM Case WHERE Id = :expectedCase.Id];
        System.assertEquals(true, expectedCase.IsClosed, 'expected case is not closed');

        Test.startTest();
            PJN_CarePlanCaseWrapper actualCarePlanCaseWrapper = new PJN_CarePlanCaseWrapper(expectedCase);
        Test.stopTest();

        System.assertEquals(expectedCase.Id, actualCarePlanCaseWrapper.caseRecord.Id, 'case record does not match');
        System.assertEquals('closed', actualCarePlanCaseWrapper.activityType, 'activity type is not set correctly');
        System.assertEquals(null, actualCarePlanCaseWrapper.programCase, 'program case should be null');
    }

    @isTest private static void constructWrapperWithProgramCase() {
        PJN_Program_Case__mdt expectedProgramCase = new PJN_Program_Case__mdt(
            MasterLabel = 'Test',
            DeveloperName = 'PJN_Test'
        );

        Test.startTest();
            PJN_CarePlanCaseWrapper actualCarePlanCaseWrapper = new PJN_CarePlanCaseWrapper(expectedProgramCase);
        Test.stopTest();

        System.assertEquals(expectedProgramCase.DeveloperName, actualCarePlanCaseWrapper.programCase.DeveloperName, 'program case record does not match');
        System.assertEquals('planned', actualCarePlanCaseWrapper.activityType, 'activity type is not set correctly');
        System.assertEquals(null, actualCarePlanCaseWrapper.caseRecord, 'case should be null');
    }
}