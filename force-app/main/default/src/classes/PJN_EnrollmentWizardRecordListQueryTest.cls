/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardRecordListQuery class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private with sharing class PJN_EnrollmentWizardRecordListQueryTest {
    @isTest private static void testGetEnrollmentWizardRecordList() {
        PJN_EnrollmentWizardRecordListQuery enrollmentRecordListQuery = new PJN_EnrollmentWizardRecordListQuery();

        Test.startTest();
            try {
                PJN_Enrollment_Wizard_Record_List__mdt result = enrollmentRecordListQuery.getEnrollmentWizardRecordList(null);
            } catch (QueryException exc) {
                System.assert(exc!=null);
                System.assertEquals('List has no rows for assignment to SObject', exc.getMessage());
            }
        Test.stopTest();
    }
}