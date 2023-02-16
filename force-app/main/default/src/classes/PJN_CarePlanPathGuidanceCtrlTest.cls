/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathGuidanceCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathGuidanceCtrlTest {
    @isTest private static void getCarePlanFields() {
        PJN_CarePlanFieldQuery mockCarePlanFieldQuery = (PJN_CarePlanFieldQuery) Test.createStub(PJN_CarePlanFieldQuery.class, new PJN_CarePlanFieldMock());
        PJN_CarePlanPathGuidanceCtrl.carePlanFieldQuery = mockCarePlanFieldQuery;
        String carePlanPathCoachingSettingDeveloperName = 'PJN_Test_Coaching_DeveloperName';

        Test.startTest();
            List<PJN_Care_Plan_Field__mdt> actualSettings = PJN_CarePlanPathGuidanceCtrl.getCarePlanFields(carePlanPathCoachingSettingDeveloperName);
        Test.stopTest();

        System.assertEquals(1, actualSettings.size());
        for(PJN_Care_Plan_Field__mdt actualSetting : actualSettings) {
            System.assertEquals(carePlanPathCoachingSettingDeveloperName, actualSetting.PJN_CarePlan_Path_Coaching_Setting__r.DeveloperName);
        }
    }
}