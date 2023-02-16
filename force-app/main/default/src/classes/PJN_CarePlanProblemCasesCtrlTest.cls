/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanProblemCasesCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanProblemCasesCtrlTest {
    @TestSetup
    static void makeData(){
        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Id activityRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case testCaseNoProgram = new Case(
            RecordTypeId = carePlanRecordTypeId,
            Status = 'Test',
            Subject = 'Care Plan No Program'
        );
        insert testCaseNoProgram;
        List<Case> activities = new List<Case> {
            new Case(
                RecordTypeId = activityRecordTypeId,
                ParentId = testCaseNoProgram.Id,
                Subject = 'Test Activity One'
            ),
            new Case(
                RecordTypeId = activityRecordTypeId,
                ParentId = testCaseNoProgram.Id,
                Subject = 'Test Activity'
            )
        };
        insert activities;
        Case testCase = new Case(
            RecordTypeId = carePlanRecordTypeId,
            Status = 'Test',
            Subject = 'Care Plan',
            PJN_Program_DeveloperName__c = 'PJN_Test_Program'
        );
        insert testCase;
        HealthCloudGA__CarePlanProblem__c testCarePlanProblem = new HealthCloudGA__CarePlanProblem__c(
            HealthCloudGA__CarePlan__c = testCase.Id,
            Name = 'Test Problem',
            PJN_Program_Problem_DeveloperName__c = 'PJN_Test_Program_Problem'
        );
        insert testCarePlanProblem;
        String expectedExistingProgramCaseDeveloperName = 'PJN_Mocked_Program_Case_One';
        String expectedProgramCaseDeveloperName = 'PJN_Mocked_Program_Case_Two';
        List<Case> expectedActivities = new List<Case> {
            new Case(
                RecordTypeId = activityRecordTypeId,
                ParentId = testCase.Id,
                PJN_CarePlan_Problem__c = testCarePlanProblem.Id,
                Subject = 'Test Activity One',
                PJN_Program_Case_DeveloperName__c = expectedExistingProgramCaseDeveloperName
            ),
            new Case(
                RecordTypeId = activityRecordTypeId,
                ParentId = testCase.Id,
                PJN_CarePlan_Problem__c = testCarePlanProblem.Id,
                Subject = 'Test Activity'
            )
        };
        insert expectedActivities;
    }

    @isTest private static void getCarePlanCases() {
        PJN_CarePlanTimelineCaseFieldQuery mockCarePlanTimelineCaseFieldQuery = (PJN_CarePlanTimelineCaseFieldQuery) Test.createStub(PJN_CarePlanTimelineCaseFieldQuery.class, new PJN_CarePlanTimelineCaseFieldMock());
        PJN_CarePlanProblemCasesCtrl.carePlanTimelineCaseFieldQuery = mockCarePlanTimelineCaseFieldQuery;
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case expectedCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId AND PJN_Program_DeveloperName__c = null];

        Test.startTest();
            List<PJN_CarePlanCaseWrapper> actualActivities = PJN_CarePlanProblemCasesCtrl.getCarePlanCases(expectedCase.Id);
        Test.stopTest();

        System.assertEquals(2, actualActivities.size());
        for(PJN_CarePlanCaseWrapper actualActivity : actualActivities) {
            System.assertEquals(expectedCase.Id, actualActivity.caseRecord.ParentId);
        }
    }

    @isTest private static void getCarePlanProblemCases() {
        PJN_ProgramCaseQuery mockProgramCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_CarePlanProblemCasesCtrl.programCaseQuery = mockProgramCaseQuery;
        PJN_CarePlanTimelineCaseFieldQuery mockCarePlanTimelineCaseFieldQuery = (PJN_CarePlanTimelineCaseFieldQuery) Test.createStub(PJN_CarePlanTimelineCaseFieldQuery.class, new PJN_CarePlanTimelineCaseFieldMock());
        PJN_CarePlanProblemCasesCtrl.carePlanTimelineCaseFieldQuery = mockCarePlanTimelineCaseFieldQuery;

        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case expectedCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId AND PJN_Program_DeveloperName__c != null];
        HealthCloudGA__CarePlanProblem__c testCarePlanProblem = [
            SELECT Id, HealthCloudGA__CarePlan__c, Name, PJN_Program_Problem_DeveloperName__c, HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c
            FROM HealthCloudGA__CarePlanProblem__c
            WHERE Name = 'Test Problem'
        ];
        Test.startTest();
            List<PJN_CarePlanCaseWrapper> actualActivities = PJN_CarePlanProblemCasesCtrl.getCarePlanProblemCases(testCarePlanProblem);
        Test.stopTest();

        System.assertEquals(3, actualActivities.size());
        for(PJN_CarePlanCaseWrapper actualActivity : actualActivities) {
            if(actualActivity.caseRecord != null) {
                System.assertEquals(expectedCase.Id, actualActivity.caseRecord.ParentId);
            } else {
                System.assertNotEquals('PJN_Mocked_Program_Case_One', actualActivity.programCase.DeveloperName);
                System.assertEquals('PJN_Mocked_Program_Case_Two', actualActivity.programCase.DeveloperName);
            }
        }
    }
}