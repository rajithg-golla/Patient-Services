@isTest
public class PJN_BulkCarePlanStartTests {

    private static final Integer DATA_SIZE = 100;

    @TestSetup
    static void makeData(){
        insert new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );

        Id patientRecTypeId = SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Patient')
            .getRecordTypeId();

        List<Account> patients = new List<Account>();
        for (Integer i=0; i<DATA_SIZE; i++) {
            patients.add(
                new Account (
                    LastName = 'Patient' + i,
                    RecordTypeId = patientRecTypeId
                )
            );
        }
        insert patients;

        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        List<Case> carePlans = new List<Case>();
        for (Account patient : patients) {
            carePlans.add(
                new Case(
                    RecordTypeId = carePlanRecTypeId,
                    AccountId = patient.Id
                )
            );
        }
        insert carePlans;

        List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>();
        for (Case carePlan : carePlans) {
            problems.add(
                new HealthCloudGA__CarePlanProblem__c(
                    Name = 'Test Care Plan Problem',
                    HealthCloudGA__CarePlan__c = carePlan.Id,
                    HealthCloudGA__SortOrder__c = 10
                )
            );
        }
        insert problems;
    }

    @isTest
    static void itShouldStart100CarePlans() {
        PJN_CarePlanHdlr.programQuery = (PJN_ProgramQuery) Test.createStub(PJN_ProgramQuery.class, new PJN_ProgramQueryMock());
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine mockCarePlanProblemMappingEngine = new PJN_MappingEngine();
        mockCarePlanProblemMappingEngine.mappingQuery = mockMappingQuery;
        PJN_CarePlanProblemHdlr mockCarePlanProblemHdlr = new PJN_CarePlanProblemHdlr();
        PJN_CarePlanProblemHdlr.carePlanProblemMappingEngine = mockCarePlanProblemMappingEngine;
        PJN_CarePlanPathAddProblemCtrl.carePlanProblemHdlr = mockCarePlanProblemHdlr;

        List<Case> carePlans = [SELECT Id, PJN_Care_Plan_Start_Status__c, PJN_Program_DeveloperName__c FROM Case];
        for (Case carePlan : carePlans) {
            carePlan.PJN_Program_DeveloperName__c = 'PJN_CLP';
            carePlan.PJN_Care_Plan_Start_Status__c = 'PJN_Initiate';
        }

        Test.startTest();
        update carePlans;
        System.assertEquals(DATA_SIZE,
            [SELECT COUNT() FROM Case WHERE PJN_Care_Plan_Start_Status__c = 'PJN_Pending'],
            'Count of care plans in pending status is incorrect'
        );
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(DATA_SIZE,
            [SELECT COUNT() FROM Case WHERE PJN_Care_Plan_Start_Status__c = 'PJN_Started'],
            'Count of care plans in started status is incorrect'
        );

        System.assertEquals(DATA_SIZE, PJN_CarePlanStartHdlr.newlyPendingIds.size(), 'Count of new ids for events is incorrect');
        System.assertEquals(DATA_SIZE, [SELECT COUNT() FROM HealthCloudGA__CarePlanProblem__c], 'Count of expected care plan problems is incorrect');
    }
}