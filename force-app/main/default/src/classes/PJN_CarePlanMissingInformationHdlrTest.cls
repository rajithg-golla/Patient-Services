/**
 * @author      Mavens
 * @group       CarePlanHdlr
 * @description Test for PJN_CarePlanMissingInformationHdlr
 */
@IsTest
private class PJN_CarePlanMissingInformationHdlrTest {

    private static final Integer BULK_SIZE = 200;

    static {
        PJN_CarePlanMissingInformationHdlr.missingInformationQuery = (PJN_MissingInformationConfigQuery) Test.createStub(PJN_MissingInformationConfigQuery.class, new PJN_MissingInformationConfigMock());
        PJN_CarePlanMissingInformationHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_ProgramCase.programCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
    }

    @TestSetup
    static void makeData(){
        Test.startTest();
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;
        CareProgramProduct product = new CareProgramProduct(
            CareProgramId = program.Id,
            PJN_Program_Developer_Name__c = 'PJN_CLP',
            PJN_NDC__c = '1234567890',
            Name = 'Test Product'
        );
        insert product;
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Test Patient'
        );
        Account physician = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            LastName = 'Test Physician'
        );
        insert new List<Account> {patient, physician};
        List<Case> carePlans = new List<Case>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            carePlans.add(
                new Case (
                    RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                    Status = 'Test ' + i,
                    Subject = 'Care Plan ' + i,
                    AccountId = patient.Id,
                    PJN_Physician__c = physician.Id,
                    PJN_Program_DeveloperName__c = 'PJN_CLP',
                    PJN_Program__c = program.Id
                )
            );
        }
        insert carePlans;

        List<PJN_Case_Field_Configuration__mdt> configList = new PJN_TestFactoryCaseFieldConfiguration().createCaseFieldsConfigurationDefaulted();
        List<CaseTeamRole> caseTeamRoleList = new List<CaseTeamRole>();
        for (PJN_Case_Field_Configuration__mdt config : configList) {
            caseTeamRoleList.add(
                new CaseTeamRole(
                    Name = config.PJN_Case_Team_Role_Mapping__c,
                    AccessLevel = 'Read'
                )
            );
        }
        Database.insert(caseTeamRoleList, false);

        HealthCloudGA__ReciprocalRole__c healthCloudRole = new HealthCloudGA__ReciprocalRole__c(
            Name='Patient',
            HealthCloudGA__InverseRole__c='Caregiver',
            RecordTypeId=SObjectType.HealthCloudGA__ReciprocalRole__c.getRecordTypeInfosByName().get('Contact Role').getRecordTypeId()
        );
        insert healthCloudRole;
        Test.stopTest();
    }

    @IsTest
    static void testIfCarePlanObtainMissingInformationStageAndActivity() {
        List<Case> carePlans = getCarePlans();
        carePlans = updateInitialEnrollmentCompleteDate(carePlans);
        Test.startTest();
        update carePlans;
        Test.stopTest();
        List<HealthCloudGA__CarePlanProblem__c> carePlanProblems = getCarePlanProblems(carePlans);
        System.assertEquals(BULK_SIZE, carePlanProblems.size(), 'Process must create the Missing Information Stage for the Care Plans');
        List<Case> missingInfos = getMissingInfoActivities(carePlans);
        System.assert(!carePlanProblems.isEmpty(), 'Process must create the Missing Information Activities for the Care Plans');
    }

    private static List<Case> getCarePlans() {
        return [
            SELECT
                Id,
                Status,
                Subject,
                AccountId,
                PJN_Physician__c,
                PJN_Program_DeveloperName__c,
                PJN_Program__c,
                PJN_Enrollment_Completed__c
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'CarePlan'
        ];
    }

    private static List<Case> updateInitialEnrollmentCompleteDate(List<Case> carePlans) {
        for (Case carePlan : carePlans) {
            carePlan.PJN_Enrollment_Completed__c = true;
        }
        return carePlans;
    }

    private static List<HealthCloudGA__CarePlanProblem__c> getCarePlanProblems(List<Case> carePlans) {
        return [
            SELECT
                Id,
                PJN_Program_Problem_DeveloperName__c,
                PJN_Status__c,
                HealthCloudGA__CarePlan__c,
                HealthCloudGA__CarePlan__r.AccountId,
                HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c,
                HealthCloudGA__CarePlan__r.PJN_Therapy_Status__c,
                HealthCloudGA__CarePlan__r.OwnerId
            FROM
                HealthCloudGA__CarePlanProblem__c
            WHERE
                HealthCloudGA__CarePlan__c IN :carePlans
            AND
                PJN_Program_Problem_DeveloperName__c = 'PJN_CLP_MI_Stage'
            AND
                PJN_Status__c = 'Open'
        ];
    }

    private static List<Case> getMissingInfoActivities(List<Case> carePlans) {
        return [
            SELECT
                Id,
                OwnerId,
                AccountId,
                PJN_Program_DeveloperName__c,
                ParentId,
                PJN_CarePlan_Problem__c,
                PJN_Program_Case_DeveloperName__c,
                Subject,
                Origin,
                RecordTypeId
            FROM
                Case
            WHERE
                ParentId IN :carePlans
        ];
    }
}