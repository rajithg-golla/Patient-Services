/*
 * @author      Mavens
 * @group       CarePlan
 * @description Unit tests for CarPlanWrapper
 */
@isTest
public with sharing class PJN_CarePlanWrapperTest {

    static Case carePlan;
    static List<HealthCloudGA__CarePlanProblem__c> problems;
    static List<Case> activities;
    static {
        carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Subject='CarePlan'
        );

        insert carePlan;

        problems = new List<HealthCloudGA__CarePlanProblem__c> {
            new HealthCloudGA__CarePlanProblem__c(
                HealthCloudGA__CarePlan__c = carePlan.Id,
                HealthCloudGA__SortOrder__c = 1,
                PJN_Program_Problem_DeveloperName__c = 'PJN_Mocked_Program_Problem_One'
            ),
            new HealthCloudGA__CarePlanProblem__c(
                HealthCloudGA__CarePlan__c = carePlan.Id,
                HealthCloudGA__SortOrder__c = 2,
                PJN_Program_Problem_DeveloperName__c = 'PJN_Mocked_Program_Problem_Two'
            )
        };

        insert problems;

        activities = new List<Case> {
            new Case(
                RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                Subject='Activity 1',
                PJN_CarePlan_Problem__c = problems[0].Id,
                ParentId = carePlan.Id
            ),
            new Case(
                RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                Subject='Activity 1',
                PJN_CarePlan_Problem__c = problems[1].Id,
                ParentId = carePlan.Id
            )
        };

        insert activities;
    }

    @isTest
    private static void itShouldConstructAWrapperGivenACarePlanId() {
        Test.startTest();
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(carePlan.Id);
        Test.stopTest();

        System.assert(wrapper.problems.keySet().containsAll(new Set<Id>{problems[0].Id, problems[1].Id}));
        System.assert(wrapper.activities.keySet().containsAll(new Set<Id>{activities[0].Id, activities[1].Id}));
    }

    @isTest
    private static void itShouldConstructAWrapperGivenACarePlan() {
        Test.startTest();
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(
            PJN_CarePlanQuery.queryById(carePlan.Id)
        );
        Test.stopTest();

        System.assert(wrapper.problems.keySet().containsAll(new Set<Id>{problems[0].Id, problems[1].Id}));
        System.assert(wrapper.activities.keySet().containsAll(new Set<Id>{activities[0].Id, activities[1].Id}));
    }

    @isTest
    private static void itShouldThrowErrorWhenStartingCarePlanWithNoProblems() {
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(carePlan); //not queried properly so no problems passed
        Test.startTest();
        Boolean errorCaught = false;
        try {
            wrapper.start();
        } catch(PJN_CarePlanWrapper.PJN_CarePlanWrapperException ex) {
            errorCaught = true;
            System.assertEquals(PJN_CarePlanWrapper.noProblemsToStart, ex.getMessage());
        }
        System.assert(errorCaught);
    }

    @isTest
    private static void itShouldStartTheCarePlan() {
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(
            PJN_CarePlanQuery.queryById(carePlan.Id)
        );
        Test.startTest();
        Map<HealthCloudGA__CarePlanProblem__c, List<Case>> returnedData = wrapper.start();
        Test.stopTest();

        System.assert(!returnedData.isEmpty());
        List<HealthCloudGA__CarePlanProblem__c> returnedProblems = new List<HealthCloudGA__CarePlanProblem__c>(returnedData.keySet());
        System.assertEquals('PJN_Mocked_Program_Problem_One', returnedProblems[0].PJN_Program_Problem_DeveloperName__c);
    }

    @isTest
    private static void itShouldStartAProblem() {
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());

        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(
            PJN_CarePlanQuery.queryById(carePlan.Id)
        );

        Test.startTest();
        wrapper.startProblem(problems[0].Id, true);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM HealthCloudGA__CarePlanProblem__c WHERE PJN_Status__c = 'Open']);
    }

    @isTest
    private static void itShouldThrowErrorWhenStartingProblemNotOnCarePlan() {
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(carePlan); //not queried properly so no problems passed
        Test.startTest();
        Boolean errorCaught = false;
        try {
            wrapper.startProblem(carePlan.Id, true);
        } catch(PJN_CarePlanWrapper.PJN_CarePlanWrapperException ex) {
            errorCaught = true;
            System.assertEquals(
                String.format(PJN_CarePlanWrapper.problemDoesNotExistOnCarePlan, new List<String>{carePlan.Id}),
                ex.getMessage()
            );
        }
        System.assert(errorCaught);
    }

    @isTest
    private static void itShouldSkipAProblem() {
        PJN_CarePlanCaseHdlr.programCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());

        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(
            PJN_CarePlanQuery.queryById(carePlan.Id)
        );
        wrapper.startProblem(problems[0].Id, true);
        Test.startTest();
        wrapper.skipProblem(problems[0].Id, true);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM HealthCloudGA__CarePlanProblem__c WHERE PJN_Status__c = 'Open']);
        System.assertEquals(1, [SELECT COUNT() FROM HealthCloudGA__CarePlanProblem__c WHERE PJN_Status__c = 'Cancelled']);
    }

    @isTest
    private static void itShouldThrowErrorWhenSkippingProblemNotOnCarePlan() {
        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(carePlan); //not queried properly so no problems passed
        Test.startTest();
        Boolean errorCaught = false;
        try {
            wrapper.skipProblem(carePlan.Id, true);
        } catch(PJN_CarePlanWrapper.PJN_CarePlanWrapperException ex) {
            errorCaught = true;
            System.assertEquals(
                String.format(PJN_CarePlanWrapper.problemDoesNotExistOnCarePlan, new List<String>{carePlan.Id}),
                ex.getMessage()
            );
        }
        System.assert(errorCaught);
    }

    @isTest
    private static void itShouldProcessClosedActivity() {
        PJN_CarePlanCaseHdlr.programCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());

        PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(
            PJN_CarePlanQuery.queryById(carePlan.Id)
        );
        Test.startTest();
        Map<HealthCloudGA__CarePlanProblem__c, List<Case>> returnedData = wrapper.activityClosed(activities[0].Id);
        Test.stopTest();

        System.assertEquals(2, returnedData.size());
        List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>(returnedData.keySet());
        System.assertEquals('Closed',problems[0].PJN_Status__c);
        System.assertEquals('Open',problems[1].PJN_Status__c);
    }
}