/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardRecordFormQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentWizardRecordFormQueryTest {
    @isTest private static void testGetEnrollmentWizardRecordForm() {
        PJN_EnrollmentWizardRecordFormQuery enrollmentRecordFormQuery = new PJN_EnrollmentWizardRecordFormQuery();
        Test.startTest();
            try {
                PJN_Enrollment_Wizard_Record_Form__mdt result = enrollmentRecordFormQuery.getEnrollmentWizardRecordForm(null);
            } catch (QueryException exc) {
                System.assert(exc!=null);
                System.assertEquals('List has no rows for assignment to SObject', exc.getMessage());
            }
        Test.stopTest();
    }
}