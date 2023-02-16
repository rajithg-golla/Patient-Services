/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanTimelineProblemCaseCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanTimelineProblemCaseCtrlTest {
    @isTest private static void getActivitySettings() {
        PJN_CarePlanTimelineCaseQuery mockCarePlanTimelineCaseQuery = (PJN_CarePlanTimelineCaseQuery) Test.createStub(PJN_CarePlanTimelineCaseQuery.class, new PJN_CarePlanTimelineCaseMock());
        PJN_CarePlanTimelineProblemCaseCtrl.carePlanTimelineCaseQuery = mockCarePlanTimelineCaseQuery;
        PJN_CarePlanTimelineCaseFieldQuery mockCarePlanTimelineCaseFieldQuery = (PJN_CarePlanTimelineCaseFieldQuery) Test.createStub(PJN_CarePlanTimelineCaseFieldQuery.class, new PJN_CarePlanTimelineCaseFieldMock());
        PJN_CarePlanTimelineProblemCaseCtrl.carePlanTimelineCaseFieldQuery = mockCarePlanTimelineCaseFieldQuery;
        String expectedProgramDeveloperName = 'PJN_Test_Program';
        String expectedActivityType = 'open';

        Test.startTest();
            Map<String, Object> actualActivitySettingsMap = PJN_CarePlanTimelineProblemCaseCtrl.getActivitySettings(expectedProgramDeveloperName, expectedActivityType);
        Test.stopTest();

        System.assertEquals(2, actualActivitySettingsMap.size());
        PJN_Care_Plan_Timeline_Case__mdt actualActivitySetting = (PJN_Care_Plan_Timeline_Case__mdt) actualActivitySettingsMap.get('activitySetting');
        System.assertEquals(expectedProgramDeveloperName, actualActivitySetting.PJN_Program__r.DeveloperName);
        System.assertEquals(expectedActivityType, actualActivitySetting.PJN_Activity_Type__c);
        List<PJN_Care_Plan_Timeline_Case_Field__mdt> actualActivityFieldSettings = (List<PJN_Care_Plan_Timeline_Case_Field__mdt>) actualActivitySettingsMap.get('activityFieldSettings');
        for(PJN_Care_Plan_Timeline_Case_Field__mdt actualActivityFieldSetting : actualActivityFieldSettings) {
            System.assertEquals(actualActivitySetting.DeveloperName, actualActivityFieldSetting.PJN_Care_Plan_Timeline_Case__r.DeveloperName);
        }
    }

    @isTest private static void getActivitySettingsWithException() {
        String expectedProgramDeveloperName = 'PJN_Does_Not_Exist';
        String expectedActivityType = 'PJN_Does_Not_Exist';

        Test.startTest();
            try {
                PJN_CarePlanTimelineProblemCaseCtrl.getActivitySettings(expectedProgramDeveloperName, expectedActivityType);
            } catch(AuraHandledException auraHandledEx) {
                System.assertEquals('System.AuraHandledException', auraHandledEx.getTypeName());
            }
        Test.stopTest();
    }
}