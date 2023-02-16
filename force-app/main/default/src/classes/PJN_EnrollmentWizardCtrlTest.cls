/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardCtrl class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private class PJN_EnrollmentWizardCtrlTest {

    static Case activityCase;
    static Account patient;
    static Account Physician;
    static Account PhysicianStaff;
    static Account caregiver;

    static {
        mockEnrollmentWizardSettings();
        createAccounts();
        createActivityCase();
    }

    static void mockEnrollmentWizardSettings() {
        PJN_EnrollmentWizardSettingQuery mockEnrollmentWizardSetting = (PJN_EnrollmentWizardSettingQuery) Test.createStub(
            PJN_EnrollmentWizardSettingQuery.class, new PJN_EnrollmentWizardSettingMock()
        );
        PJN_EnrollmentWizardCtrl.enrollmentSettingQuery = mockEnrollmentWizardSetting;

        PJN_EnrollmentWizardStepQuery mockEnrollmentWizardStep = (PJN_EnrollmentWizardStepQuery) Test.createStub(
            PJN_EnrollmentWizardStepQuery.class, new PJN_EnrollmentWizardStepMock()
        );
        PJN_EnrollmentWizardCtrl.enrollmentStepQuery = mockEnrollmentWizardStep;

        PJN_EnrollmentWizardComponentQuery mockEnrollmentWizardComponent = (PJN_EnrollmentWizardComponentQuery) Test.createStub(
            PJN_EnrollmentWizardComponentQuery.class, new PJN_EnrollmentWizardComponentMock()
        );
        PJN_EnrollmentWizardCtrl.enrollmentComponentQuery = mockEnrollmentWizardComponent;
    }

    static void createAccounts() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId(),
                'LastName' => 'Patient Test'
            }
        );
        Physician = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Physician').getRecordTypeId(),
                'LastName' => 'Physician Test'
            }
        );
        PhysicianStaff = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Staff').getRecordTypeId(),
                'LastName' => 'Staff Test'
            }
        );
        caregiver = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Caregiver').getRecordTypeId(),
                'LastName' => 'Caregiver Test'
            }
        );
    }

    static void createActivityCase() {
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        activityCase = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Activity Case',
                'AccountId' => patient.Id,
                'PJN_Caregiver__c' => caregiver.Id,
                'PJN_Physician__c' => Physician.Id,
                'PJN_Staff__c' => PhysicianStaff.Id,
                'PJN_Program_DeveloperName__c' => 'CLP_TEST'
            }
        );
    }

    @isTest private static void testNoSettingsError() {
        Test.startTest();
            try {
                PJN_EnrollmentWizardCtrl.createCarePlan('PJN_Inexistent_Program_Setting', patient.Id, activityCase.Id);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assertEquals('No enrollment settings found for program PJN_Inexistent_Program_Setting', exc.getMessage());
            }
        Test.stopTest();
    }

    @isTest private static void testCreateCarePlan() {
        Test.startTest();
            Id carePlanId = PJN_EnrollmentWizardCtrl.createCarePlan('CLP_TEST', patient.Id, activityCase.Id);
        Test.stopTest();

        Id carePlanRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId();
        System.assertEquals(carePlanId, [SELECT Id FROM Case
                                        WHERE RecordTypeId = :carePlanRecordTypeId
                                        AND PJN_Program_DeveloperName__c = 'CLP_TEST'
                                        AND AccountId = :patient.Id
                                        AND PJN_Physician__c = :Physician.Id
                                        AND PJN_Enrollment_Activity__c = :activityCase.Id].Id);

        Id activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId();
        System.assertEquals(activityCase.Id, [SELECT Id FROM Case
                                            WHERE RecordTypeId = :activityRecordTypeId
                                            AND ParentId = :carePlanId].Id);
    }

    @isTest private static void testCreateCarePlanException() {
        Test.startTest();
            try {
                PJN_EnrollmentWizardCtrl.createCarePlan('CLP_TEST', activityCase.Id, activityCase.Id);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assert(exc.getMessage().contains('FIELD_INTEGRITY_EXCEPTION'));
            }
        Test.stopTest();
    }

    @isTest private static void testGetEnrollmentWizardSteps() {
        Test.startTest();
            List<PJN_Enrollment_Wizard_Step__mdt> stepList = PJN_EnrollmentWizardCtrl.getEnrollmentWizardSteps('CLP_TEST');
            System.assertEquals(2, stepList.size());
        Test.stopTest();
    }

    @isTest private static void testGetEnrollmentWizardStepsException() {
        Test.startTest();
            try {
                PJN_EnrollmentWizardCtrl.getEnrollmentWizardSteps(null);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assertEquals('No enrollment settings found. Please contact your administrator',
                                    exc.getMessage());
            }
        Test.stopTest();
    }

    @isTest private static void testGetEnrollmentWizardComponents() {
        Test.startTest();
            List<PJN_Enrollment_Wizard_Component__mdt> componentList = PJN_EnrollmentWizardCtrl.getEnrollmentWizardComponents('m0a1D000001Caq8');
            System.assertEquals(2, componentList.size());
        Test.stopTest();
    }

    @isTest private static void testGetEnrollmentWizardComponentsException() {
        Test.startTest();
            try {
                PJN_EnrollmentWizardCtrl.getEnrollmentWizardComponents(null);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assertEquals('No enrollment settings found. Please contact your administrator',
                                    exc.getMessage());
            }
        Test.stopTest();
    }
}