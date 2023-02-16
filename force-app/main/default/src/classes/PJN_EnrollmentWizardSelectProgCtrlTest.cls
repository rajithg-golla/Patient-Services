/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_EnrollmentWizardSelectProgramCtrl class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) private class PJN_EnrollmentWizardSelectProgCtrlTest {
    @isTest private static void testGetProgramList() {
        List<CareProgram> programListToInsert = new List<CareProgram>();
        programListToInsert.add(
            new CareProgram(
                Name = 'Cholecap Care',
                PJN_Program_DeveloperName__c = 'PJN_CLP',
                StartDate = System.today(),
                EndDate = System.today().addDays(1)
            )
        );
        programListToInsert.add(
            new CareProgram(
                Name = 'Cholecap Care 2',
                PJN_Program_DeveloperName__c = 'PJN_Cholecap_Care_2',
                StartDate = System.today().addDays(-5),
                EndDate = System.today().addDays(-1)
            )
        );
        insert programListToInsert;

        Test.startTest();
            List<Map<String, String>> programList = PJN_EnrollmentWizardSelectProgramCtrl.getProgramList();
            System.assertEquals(1,programList.size());
        Test.stopTest();
    }
}