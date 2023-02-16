/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathCoachingCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathCoachingCtrlTest {
    @isTest private static void getCarePlanPathCoachingSettingsComponent() {
        PJN_CarePlanPathCoachingSettingQuery mockCarePlanPathCoachingSettingQuery = (PJN_CarePlanPathCoachingSettingQuery) Test.createStub(PJN_CarePlanPathCoachingSettingQuery.class, new PJN_CarePlanPathCoachSettingMock());
        PJN_CarePlanPathCoachingCtrl.carePlanPathCoachingSettingQuery = mockCarePlanPathCoachingSettingQuery;
        String expectedProgramProblemDeveloperName = 'PJN_Test_Program_Problem_DeveloperName';

        Test.startTest();
            List<PJN_CarePlan_Path_Coaching_Setting__mdt> actualSettings = PJN_CarePlanPathCoachingCtrl.getCarePlanPathCoachingSettingsComponent(expectedProgramProblemDeveloperName);
        Test.stopTest();

        System.assertEquals(1, actualSettings.size());
        for(PJN_CarePlan_Path_Coaching_Setting__mdt actualSetting : actualSettings) {
            System.assertEquals(expectedProgramProblemDeveloperName, actualSetting.PJN_Program_Problem__r.DeveloperName);
        }
    }
}