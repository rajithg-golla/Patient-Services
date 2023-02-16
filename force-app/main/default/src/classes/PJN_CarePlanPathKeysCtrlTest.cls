/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathKeysCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathKeysCtrlTest {
    @isTest private static void getCarePlanFields() {
        PJN_CarePlanPathKeySettingQuery mockCarePlanPathKeySettingQuery = (PJN_CarePlanPathKeySettingQuery) Test.createStub(PJN_CarePlanPathKeySettingQuery.class, new PJN_CarePlanPathKeySettingMock());
        PJN_CarePlanPathKeysCtrl.carePlanPathKeySettingQuery = mockCarePlanPathKeySettingQuery;
        String carePlanPathCoachingSettingDeveloperName = 'PJN_Test_Coaching_DeveloperName';

        Test.startTest();
            PJN_CarePlan_Path_Keys_Setting__mdt actualSetting = PJN_CarePlanPathKeysCtrl.getCarePlanPathKeyFieldsSetting(carePlanPathCoachingSettingDeveloperName);
        Test.stopTest();

        System.assertEquals(carePlanPathCoachingSettingDeveloperName, actualSetting.PJN_CarePlan_Path_Coaching_Setting__r.DeveloperName);
    }

    @isTest private static void getCarePlanFieldsException() {
        String carePlanPathCoachingSettingDeveloperName = 'PJN_Does_Not_Exist';

        Test.startTest();
            try {
                PJN_CarePlanPathKeysCtrl.getCarePlanPathKeyFieldsSetting(carePlanPathCoachingSettingDeveloperName);
            } catch(AuraHandledException auraHandledEx) {
                System.assertEquals('System.AuraHandledException', auraHandledEx.getTypeName());
            }
        Test.stopTest();
    }
}