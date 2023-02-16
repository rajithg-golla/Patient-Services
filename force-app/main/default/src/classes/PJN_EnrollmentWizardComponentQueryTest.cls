/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardComponentQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentWizardComponentQueryTest {
    @isTest private static void testGetEnrollmentComponentsByStep() {
        PJN_EnrollmentWizardComponentQuery enrollmentComponentQuery = new PJN_EnrollmentWizardComponentQuery();
        Test.startTest();
            List<PJN_Enrollment_Wizard_Component__mdt> result = enrollmentComponentQuery.getEnrollmentComponentsByStep(null);
        Test.stopTest();
        System.assert(result.isEmpty());
    }
}