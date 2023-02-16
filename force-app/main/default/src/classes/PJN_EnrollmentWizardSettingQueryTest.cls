/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardSettingQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentWizardSettingQueryTest {
    @isTest private static void testGetAllSettingsByProgram() {
        PJN_EnrollmentWizardSettingQuery enrollmentSettingQuery = new PJN_EnrollmentWizardSettingQuery();
        Test.startTest();
            Map<String, PJN_Enrollment_Wizard_Setting__mdt> result = enrollmentSettingQuery.getAllSettingsByProgram();
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}