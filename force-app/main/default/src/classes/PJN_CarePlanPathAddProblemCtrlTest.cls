/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathAddProblemCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathAddProblemCtrlTest {
    @isTest private static void getProgramProblemsInLibraryFromDeveloperName() {
        PJN_ProgramProblemQuery mockProgramProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_CarePlanPathAddProblemCtrl.programProblemQuery = mockProgramProblemQuery;
        String expectedProgramDeveloperName = 'PJN_Test_Program';

        Test.startTest();
            List<PJN_Program_Problem__mdt> actualProgramProblems = PJN_CarePlanPathAddProblemCtrl.getProgramProblemsInLibrary(expectedProgramDeveloperName);
        Test.stopTest();

        System.assertEquals(2, actualProgramProblems.size());
        for(PJN_Program_Problem__mdt actualProgramProblem : actualProgramProblems) {
            System.assertEquals(true, actualProgramProblem.PJN_Is_Library__c);
            System.assertEquals(expectedProgramDeveloperName, actualProgramProblem.PJN_Program__r.DeveloperName);
        }
    }

    @isTest private static void addProgramProblemToCarePlanFromProgramProblem() {
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine mockCarePlanProblemMappingEngine = new PJN_MappingEngine();
        mockCarePlanProblemMappingEngine.mappingQuery = mockMappingQuery;
        PJN_CarePlanProblemHdlr mockCarePlanProblemHdlr = new PJN_CarePlanProblemHdlr();
        PJN_CarePlanProblemHdlr.carePlanProblemMappingEngine = mockCarePlanProblemMappingEngine;
        PJN_CarePlanPathAddProblemCtrl.carePlanProblemHdlr = mockCarePlanProblemHdlr;

        Case expectedCarePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Origin = 'Program',
            Subject = 'Test Care Plan'
        );
        insert expectedCarePlan;

        HealthCloudGA__CarePlanProblem__c carePlanProblem = new HealthCloudGA__CarePlanProblem__c(
            Name = 'Test Care Plan Problem',
            HealthCloudGA__CarePlan__c = expectedCarePlan.Id,
            HealthCloudGA__SortOrder__c = 10
        );
        insert carePlanProblem;

        PJN_Program_Problem__mdt expectedProgramProblem = new PJN_Program_Problem__mdt(
            MasterLabel = 'Test Program Problem',
            DeveloperName = 'PJN_Test_Program_Problem',
            PJN_Is_Standard__c = true,
            PJN_Is_Library__c = false,
            PJN_Order__c = 10
        );

        Test.startTest();
            HealthCloudGA__CarePlanProblem__c actualCarePlanProblem = PJN_CarePlanPathAddProblemCtrl.addProgramProblem(expectedCarePlan.Id, expectedProgramProblem);
        Test.stopTest();

        System.assertNotEquals(null, actualCarePlanProblem);
        System.assertEquals(expectedCarePlan.Id, actualCarePlanProblem.HealthCloudGA__CarePlan__c);
        System.assertEquals(expectedProgramProblem.DeveloperName, actualCarePlanProblem.PJN_Program_Problem_DeveloperName__c);
        System.assertNotEquals(expectedProgramProblem.PJN_Order__c, actualCarePlanProblem.HealthCloudGA__SortOrder__c);
    }
}