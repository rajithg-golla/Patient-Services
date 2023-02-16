/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardRecordListCtrl class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private class PJN_EnrollmentWizardRecordListCtrlTest {
    @testSetup private static void setup() {

        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient Test'
            }
        );
        Account physician = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                'LastName' => 'Physician Test'
            }
        );
        Account physicianStaff = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId(),
                'LastName' => 'Staff Test'
            }
        );
        Account caregiver = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId(),
                'LastName' => 'Caregiver Test'
            }
        );

        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case activityCase = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Activity Case',
                'AccountId' => patient.Id,
                'PJN_Caregiver__c' => caregiver.Id,
                'PJN_Physician__c' => physician.Id,
                'PJN_Staff__c' => physicianStaff.Id,
                'PJN_Program_DeveloperName__c' => 'PJN_CLP'
            }
        );
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

    @isTest private static void testGetEnrollmentWizardRecordListException() {
        mockEnrollmentWizardSettings();
        PJN_EnrollmentWizardRecordListQuery mockEnrollmentWizardRecordList = (PJN_EnrollmentWizardRecordListQuery) Test.createStub(
            PJN_EnrollmentWizardRecordListQuery.class, new PJN_EnrollmentWizardListMock()
        );
        PJN_EnrollmentWizardRecordListCtrl.enrollmentRecordListQuery = mockEnrollmentWizardRecordList;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id carePlanId = PJN_EnrollmentWizardCtrl.createCarePlan('CLP_TEST', patient.Id, activityCase.Id);
        Test.startTest();
            try {
                PJN_EnrollmentWizardRecordListCtrl.getRecords(null, carePlanId);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assertEquals('No list definition found. Please contact your system administrator.',
                                    exc.getMessage());
            }
        Test.stopTest();
    }

    @isTest private static void testGetEnrollmentWizardRecordList() {
        mockEnrollmentWizardSettings();
        PJN_EnrollmentWizardRecordListQuery mockEnrollmentWizardRecordList = (PJN_EnrollmentWizardRecordListQuery) Test.createStub(
            PJN_EnrollmentWizardRecordListQuery.class, new PJN_EnrollmentWizardListMock()
        );
        PJN_EnrollmentWizardRecordListCtrl.enrollmentRecordListQuery = mockEnrollmentWizardRecordList;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id carePlanId = PJN_EnrollmentWizardCtrl.createCarePlan('CLP_TEST', patient.Id, activityCase.Id);
        List<HealthCloudGA__EhrMedicationPrescription__c> prescriptionList = new List<HealthCloudGA__EhrMedicationPrescription__c>();
        prescriptionList.add(
            new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlanId,
                HealthCloudGA__DispenseMedicationCode__c = 'Code1'
            )
        );
        prescriptionList.add(
            new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlanId,
                HealthCloudGA__DispenseMedicationCode__c = 'Code2'
            )
        );
        insert prescriptionList;

        Test.startTest();
            PJN_DataTable listRecords = PJN_EnrollmentWizardRecordListCtrl.getRecords('m0a1D000001Caq8', carePlanId);
            System.assertEquals(2, listRecords.data.size());
            System.assertEquals(2, listRecords.columns.size());
        Test.stopTest();
    }

    @isTest private static void testDeleteRecord() {
        PJN_EnrollmentWizardRecordListQuery mockEnrollmentWizardRecordList = (PJN_EnrollmentWizardRecordListQuery) Test.createStub(
            PJN_EnrollmentWizardRecordListQuery.class, new PJN_EnrollmentWizardListMock()
        );
        PJN_EnrollmentWizardRecordListCtrl.enrollmentRecordListQuery = mockEnrollmentWizardRecordList;

        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];

        Test.startTest();
            PJN_EnrollmentWizardRecordListCtrl.deleteRecord(activityCase);
            System.assertEquals(0, [SELECT count() FROM Case
                                    WHERE Id = :activityCase.Id]);
        Test.stopTest();
    }

    @isTest private static void testDeleteRecordError() {
        PJN_EnrollmentWizardRecordListQuery mockEnrollmentWizardRecordList = (PJN_EnrollmentWizardRecordListQuery) Test.createStub(
            PJN_EnrollmentWizardRecordListQuery.class, new PJN_EnrollmentWizardListMock()
        );
        PJN_EnrollmentWizardRecordListCtrl.enrollmentRecordListQuery = mockEnrollmentWizardRecordList;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];

        Test.startTest();
            try {
                PJN_EnrollmentWizardRecordListCtrl.deleteRecord(patient);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assert(exc.getMessage().contains(Label.PJN_Enrollment_Wizard_Exception_Message.replace('{0}','')));
            }
        Test.stopTest();
    }

}