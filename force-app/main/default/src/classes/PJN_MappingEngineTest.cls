/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngine
 */
@isTest(isParallel=true) private with sharing class PJN_MappingEngineTest {
    @isTest private static void initiate() {
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine actualMappingEngine = new PJN_MappingEngine();
        String expectedMappingJob = 'PJN_Test_Mapping_Job';

        Test.startTest();
            actualMappingEngine.initiate(expectedMappingJob);
        Test.stopTest();

        System.assertNotEquals(null, actualMappingEngine, 'not inittiated');
        System.assertNotEquals(null, PJN_MappingEngine.mappingJobQuery, 'job query not inittiated');
        System.assertNotEquals(null, actualMappingEngine.mappingQuery, 'query not inittiated');
        System.assertNotEquals(null, actualMappingEngine.mappingJob, 'job not inittiated');
        System.assertNotEquals(null, PJN_MappingEngine.mappingTypes, 'types not inittiated');
    }

    @isTest private static void initiateWithError() {
        String expectedMappingJob = 'PJN_Does_Not_Exist';
        PJN_MappingEngine actualMappingEngine = new PJN_MappingEngine();

        Test.startTest();
            try {
                actualMappingEngine.initiate(expectedMappingJob);
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(PJN_MappingEngineException mappingEngineEx) {
                System.assertEquals('Mapping Job ' + expectedMappingJob + ' is not defined.', mappingEngineEx.getMessage(), 'Incorrect error message');
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }

    @isTest private static void run() {
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine actualMappingEngine = new PJN_MappingEngine();
        actualMappingEngine.mappingQuery = mockMappingQuery;
        String expectedMappingJob = 'PJN_Test_Mapping_Job';
        actualMappingEngine.initiate(expectedMappingJob);

        Case sourceCase = new Case(
            Subject = 'Test Source Case'
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );
        insert targetCase;

        Test.startTest();
            Case actualCase = (Case) actualMappingEngine.run(new Map<String, Id> { 'Case' => sourceCase.Id }, targetCase);
        Test.stopTest();

        System.assertEquals(targetCase.Id, actualCase.Id, 'incorrect case');
        System.assertNotEquals(sourceCase.Subject, actualCase.Subject, 'incorrect subject');
    }

    @isTest private static void runMultiple() {
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine actualMappingEngine = new PJN_MappingEngine();
        actualMappingEngine.mappingQuery = mockMappingQuery;
        String expectedMappingJob = 'PJN_Test_Mapping_Job';
        actualMappingEngine.initiate(expectedMappingJob);

        List<Case> sourceCases = new List<Case>();
        List<Case> targetCases = new List<Case>();
        for(Integer index = 0; index < 201; index++) {
            sourceCases.add(
                new Case(
                    Subject = 'Test Source Case ' + index
                )
            );
            targetCases.add(
                new Case(
                    Subject = 'Test Target Case ' + index
                )
            );
        }
        insert sourceCases;
        insert targetCases;
        List<Id> sourceIds = new List<Id>();
        for(Case sourceCase : sourceCases) {
            sourceIds.add(sourceCase.Id);
        }

        Test.startTest();
            Map<String, SObject> actualCaseMap = actualMappingEngine.run(new Map<String, List<Id>> { 'Case' =>  sourceIds }, targetCases );
        Test.stopTest();


        System.assertEquals(201, actualCaseMap.size(), 'incorrect cases');
    }
}