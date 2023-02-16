/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanStatusCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanStatusCtrlTest {
    @isTest private static void getCarePlanFields() {
        PJN_CarePlanFieldQuery mockCarePlanFieldQuery = (PJN_CarePlanFieldQuery) Test.createStub(PJN_CarePlanFieldQuery.class, new PJN_CarePlanFieldMock());
        PJN_CarePlanStatusCtrl.carePlanFieldQuery = mockCarePlanFieldQuery;
        String carePlanProgramDeveloperName = 'PJN_Test_Program_DeveloperName';

        Test.startTest();
            List<PJN_Care_Plan_Field__mdt> actualSettings = PJN_CarePlanStatusCtrl.getCarePlanFields(carePlanProgramDeveloperName);
        Test.stopTest();

        System.assertEquals(1, actualSettings.size());
        for(PJN_Care_Plan_Field__mdt actualSetting : actualSettings) {
            System.assertEquals(carePlanProgramDeveloperName, actualSetting.PJN_Program__r.DeveloperName);
        }
    }
}