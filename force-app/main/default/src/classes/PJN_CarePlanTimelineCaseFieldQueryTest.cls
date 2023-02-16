/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanTimelineCaseFieldQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanTimelineCaseFieldQueryTest {
    @isTest private static void queryByCarePlanProgram() {
        PJN_CarePlanTimelineCaseFieldQuery carePlanTimelineCaseFieldQuery = new PJN_CarePlanTimelineCaseFieldQuery();

        Test.startTest();
            List<PJN_Care_Plan_Timeline_Case_Field__mdt> actualCarePlanTimelineCaseFields = carePlanTimelineCaseFieldQuery.queryByCarePlanProgram('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualCarePlanTimelineCaseFields.size());
    }

    @isTest private static void queryByCarePlanTimelineCase() {
        PJN_CarePlanTimelineCaseFieldQuery carePlanTimelineCaseFieldQuery = new PJN_CarePlanTimelineCaseFieldQuery();

        Test.startTest();
            List<PJN_Care_Plan_Timeline_Case_Field__mdt> actualCarePlanTimelineCaseFields = carePlanTimelineCaseFieldQuery.queryByCarePlanTimelineCase('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualCarePlanTimelineCaseFields.size());
    }
}