/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardStepQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentWizardStepQueryTest {
    @isTest private static void testGetEnrollmentStepsByProgram() {
        PJN_EnrollmentWizardSettingQuery enrollmentSettingQuery = new PJN_EnrollmentWizardSettingQuery();
        String programDevName;
        for (String key : enrollmentSettingQuery.getAllSettingsByProgram().keySet()) {
            programDevName = key;
            break;
        }
        if (programDevName != null) {
            PJN_EnrollmentWizardStepQuery enrollmentStepQuery = new PJN_EnrollmentWizardStepQuery();
            Test.startTest();
                List<PJN_Enrollment_Wizard_Step__mdt> result = enrollmentStepQuery.getEnrollmentStepsByProgram(programDevName);
            Test.stopTest();

            System.assertNotEquals(null, result);
        }
    }

    @isTest private static void testGetEnrollmentStepsByProgramDoesNotExist() {
        PJN_EnrollmentWizardStepQuery enrollmentStepQuery = new PJN_EnrollmentWizardStepQuery();
        Test.startTest();
            try {
                enrollmentStepQuery.getEnrollmentStepsByProgram('PJN_Does_Not_Exist');
            } catch (Exception exc) {
                System.assert(exc!=null);
            }
        Test.stopTest();
    }
}