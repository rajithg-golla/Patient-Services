/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathKeySettingQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathKeySettingQueryTest {
    @isTest private static void queryByCarePlanCoachSettingDeveloperName() {
        PJN_CarePlanPathKeySettingQuery carePlanPathKeySettingQuery = new PJN_CarePlanPathKeySettingQuery();

        Test.startTest();
            try {
                carePlanPathKeySettingQuery.queryByCarePlanCoachSettingDeveloperName('PJN_Does_Not_Exist');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage());
            }
        Test.stopTest();
    }
}