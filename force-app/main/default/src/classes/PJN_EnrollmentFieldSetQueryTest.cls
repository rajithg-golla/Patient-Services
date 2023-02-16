/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentFieldSetQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentFieldSetQueryTest {
    @isTest private static void queryByForm() {
        PJN_EnrollmentFieldSetQuery enrollmentFieldSetQuery = new PJN_EnrollmentFieldSetQuery();

        Test.startTest();
            List<PJN_Enrollment_Field_Set__mdt> actualEnrollmentFields = enrollmentFieldSetQuery.queryByForm(null);
        Test.stopTest();

        System.assertEquals(0, actualEnrollmentFields.size());
    }
}