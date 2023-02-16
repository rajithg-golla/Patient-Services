/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathCoachingSettingQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathCoachingSettingQueryTest {
    @isTest private static void queryByProgramProblemDeveloperName() {
        PJN_CarePlanPathCoachingSettingQuery carePlanPathCoachingSettingQuery = new PJN_CarePlanPathCoachingSettingQuery();

        Test.startTest();
            List<PJN_CarePlan_Path_Coaching_Setting__mdt> actualCarePlanPathCoachingSettings = carePlanPathCoachingSettingQuery.queryByProgramProblemDeveloperName('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualCarePlanPathCoachingSettings.size());
    }
}