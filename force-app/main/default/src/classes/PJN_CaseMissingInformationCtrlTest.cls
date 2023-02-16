/**
 * @author      Mavens
 * @group       MissingInformation
 * @description Test for PJN_CaseMissingInformationCtrl
 */
@IsTest
private class PJN_CaseMissingInformationCtrlTest {

    static {
        PJN_CarePlanMissingInformationHdlr.missingInformationQuery = (PJN_MissingInformationConfigQuery) Test.createStub(PJN_MissingInformationConfigQuery.class, new PJN_MissingInformationConfigMock());
        PJN_CarePlanMissingInformationHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_MappingEngine.mappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_CarePlanProblemHdlr.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_ProgramCase.programCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_CaseMissingInformationCtrl.missingInformationConfigQuery = (PJN_MissingInformationConfigQuery) Test.createStub(PJN_MissingInformationConfigQuery.class, new PJN_MissingInformationConfigMock());
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
        Case carePlan = new Case (
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan',
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            PJN_Program__c = program.Id
        );
        insert carePlan;

        insert new Case (
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MVN_Missing_Information').getRecordTypeId(),
            ParentId = carePlan.Id,
            PJN_Program__c = program.Id
        );

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
    static void testIfGetMissingInfoFields() {
        Case missingInfoActivity = getMissingInfoActivity();
        List<String> missingInfoFields;
        Test.startTest();
        missingInfoFields = PJN_CaseMissingInformationCtrl.getMissingInformationFields(missingInfoActivity.Id);
        Test.stopTest();
        System.assertNotEquals(null, missingInfoFields, 'Care Plan Id is null for the method.');
        System.assert(!missingInfoFields.isEmpty(), 'No missing info fields found.');
        System.assertEquals(2, missingInfoFields.size(), 'Missing info fields must include patient address and gender only.');
    }

    @IsTest
    static void testIfGetMissingInfoFieldsNoResults() {
        Account patient = getPatient();
        patient.HealthCloudGA__Gender__pc = 'Female';
        patient.PJN_Primary_Address__c = createAddress(patient.Id);
        update patient;
        Case missingInfoActivity = getMissingInfoActivity();
        List<String> missingInfoFields;
        Test.startTest();
        missingInfoFields = PJN_CaseMissingInformationCtrl.getMissingInformationFields(missingInfoActivity.Id);
        Test.stopTest();
        System.assertNotEquals(null, missingInfoFields, 'Care Plan Id is null for the method.');
        System.assert(missingInfoFields.isEmpty(), 'There should not be any missing info field.');
    }

    private static Account getPatient() {
        return [
            SELECT
                Id,
                HealthCloudGA__Gender__pc,
                PJN_Primary_Address__c
            FROM
                Account
            WHERE
                RecordType.DeveloperName = 'PJN_Patient'
            LIMIT 1
        ];
    }

    private static Id createAddress(Id patientId) {
        PJN_Contact_Information__c ci = new PJN_Contact_Information__c(
            PJN_Account__c = patientId,
            PJN_Address_Line_1__c = 'Main Street 123',
            PJN_City__c = 'Chicago',
            PJN_Postal_Code__c = '60606',
            PJN_State__c = 'IL',
            PJN_Country__c = 'United States'
        );
        insert ci;
        return ci.Id;
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

    private static Case getMissingInfoActivity() {
        return [
            SELECT
                Id,
                ParentId,
                PJN_Program_DeveloperName__c,
                PJN_Program__c
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'MVN_Missing_Information'
            LIMIT 1
        ];
    }
}