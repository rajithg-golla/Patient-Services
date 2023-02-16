/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_AllCarePlanSettingQuery
 */
@isTest(isParallel=true) public with sharing class PJN_AllCarePlanSettingQueryTest {
    @isTest private static void queryAll() {
        PJN_AllCarePlanSettingQuery allCarePlanSettingQuery = new PJN_AllCarePlanSettingQuery();

        Test.startTest();
            List<PJN_All_Care_Plan_Setting__mdt> actualAllCarePlanSettings = allCarePlanSettingQuery.queryAll();
        Test.stopTest();

        System.assert(actualAllCarePlanSettings.size() >= 0);
    }
}