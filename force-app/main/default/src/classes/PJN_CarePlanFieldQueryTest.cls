/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanFieldQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanFieldQueryTest {
    @isTest private static void queryByCoachingSettingDeveloperName() {
        PJN_CarePlanFieldQuery carePlanFieldQuery = new PJN_CarePlanFieldQuery();

        Test.startTest();
            List<PJN_Care_Plan_Field__mdt> actualCarePlanFields = carePlanFieldQuery.queryByCoachingSettingDeveloperName('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualCarePlanFields.size());
    }

    @isTest private static void queryByCarePlanProgramDeveloperName() {
        PJN_CarePlanFieldQuery carePlanFieldQuery = new PJN_CarePlanFieldQuery();

        Test.startTest();
            List<PJN_Care_Plan_Field__mdt> actualCarePlanFields = carePlanFieldQuery.queryByCarePlanProgramDeveloperName('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualCarePlanFields.size());
    }
}