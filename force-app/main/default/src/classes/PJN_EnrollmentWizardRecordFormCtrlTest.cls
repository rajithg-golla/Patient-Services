/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardRecordFormCtrl class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private class PJN_EnrollmentWizardRecordFormCtrlTest {
    @isTest private static void testGetEnrollmentWizardRecordForms() {
        PJN_EnrollmentWizardRecordFormQuery mockEnrollmentWizardRecordForm = (PJN_EnrollmentWizardRecordFormQuery) Test.createStub(
            PJN_EnrollmentWizardRecordFormQuery.class, new PJN_EnrollmentWizardFormMock()
        );
        PJN_EnrollmentWizardRecordFormCtrl.enrollmentRecordFormQuery = mockEnrollmentWizardRecordForm;
        PJN_EnrollmentFieldSetQuery mockEnrollmentFieldSetQuery = (PJN_EnrollmentFieldSetQuery) Test.createStub(
            PJN_EnrollmentFieldSetQuery.class, new PJN_EnrollmentFieldSetMock()
        );
        PJN_EnrollmentWizardRecordFormCtrl.enrollmentFieldSetQuery = mockEnrollmentFieldSetQuery;

        Test.startTest();
            Map<String, Object> actualFormSettingMap = PJN_EnrollmentWizardRecordFormCtrl.getEnrollmentWizardRecordForms('m0a1D000001Caq8');
        Test.stopTest();

        PJN_Enrollment_Wizard_Record_Form__mdt formSetting = (PJN_Enrollment_Wizard_Record_Form__mdt) actualFormSettingMap.get('setting');
        System.assert(formSetting != null);
        System.assertEquals(Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                        formSetting.PJN_RecordType_DeveloperName__c);
        List<PJN_Enrollment_Field_Set__mdt> enrollmentFields = (List<PJN_Enrollment_Field_Set__mdt>) actualFormSettingMap.get('fields');
        System.assert(enrollmentFields != null);
        System.assertEquals(1, enrollmentFields.size(), 'incorrect number of records');
        System.assertEquals('Name', enrollmentFields.get(0).PJN_Field_API_Name__c, 'incorrect field api name');
    }

    @isTest private static void testGetEnrollmentWizardRecordFormsException() {
        PJN_EnrollmentWizardRecordFormQuery mockEnrollmentWizardRecordForm = (PJN_EnrollmentWizardRecordFormQuery) Test.createStub(
            PJN_EnrollmentWizardRecordFormQuery.class, new PJN_EnrollmentWizardFormMock()
        );
        PJN_EnrollmentWizardRecordFormCtrl.enrollmentRecordFormQuery = mockEnrollmentWizardRecordForm;
        Test.startTest();
            try {
                PJN_EnrollmentWizardRecordFormCtrl.getEnrollmentWizardRecordForms(null);
            } catch (AuraHandledException exc) {
                System.assert(exc!=null);
                System.assertEquals('No form definition found. Please contact your system administrator.',
                                    exc.getMessage());
            }
        Test.stopTest();
    }

}