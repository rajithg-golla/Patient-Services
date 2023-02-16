/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanTimelineCaseQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanTimelineCaseQueryTest {
    @isTest private static void queryByProgramAndActivityType() {
        PJN_CarePlanTimelineCaseQuery carePlanPathCoachingSettingQuery = new PJN_CarePlanTimelineCaseQuery();

        Test.startTest();
            try {
                carePlanPathCoachingSettingQuery.queryByProgramAndActivityType('PJN_Does_Not_Exist', 'PJN_Does_Not_Exist');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage());
            }

        Test.stopTest();
    }
}