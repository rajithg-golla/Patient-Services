/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_AllCarePlanFieldSettingQuery
 */
@isTest(isParallel=true) public with sharing class PJN_AllCarePlanFieldSettingQueryTest {
    @isTest private static void queryBySettingDeveloperNames() {
        PJN_AllCarePlanFieldSettingQuery allCarePlanFieldSettingQuery = new PJN_AllCarePlanFieldSettingQuery();
        Set<String> allCarePlanSettingDeveloperNamesSet = new Set<String> {
            'PJN_Does_Not_Exist'
        };

        Test.startTest();
            List<PJN_All_Care_Plan_Setting_Field__mdt> actualAllCarePlanFieldSettings = allCarePlanFieldSettingQuery.queryBySettingDeveloperNames(allCarePlanSettingDeveloperNamesSet);
        Test.stopTest();

        System.assertEquals(0, actualAllCarePlanFieldSettings.size());
    }
}