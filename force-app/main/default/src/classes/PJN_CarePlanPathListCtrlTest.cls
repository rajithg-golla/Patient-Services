/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathListCtrl
 */
@isTest(isParallel=true)
public with sharing class PJN_CarePlanPathListCtrlTest {

    @isTest
    private static void getCareplans() {
        Account expectedAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Ing'
        );
        insert expectedAccount;
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = expectedAccount.Id,
            Subject = 'Care Plan'
        );
        insert expectedCase;

        Test.startTest();
            List<Case> actualCareplans = PJN_CarePlanPathListCtrl.getCareplans(expectedAccount.Id);
        Test.stopTest();

        System.assertEquals(false, actualCareplans.isEmpty());
        Case actualCareplan = actualCareplans.get(0);
        System.assertEquals(expectedCase.Id, actualCareplan.Id);
        System.assertEquals(expectedCase.Subject, actualCareplan.Subject);
    }

    @isTest
    private static void getAllCarePlanSettingsByProgramDeveloperName() {
        PJN_AllCarePlanSettingQuery mockAllCarePlanSettingQuery = (PJN_AllCarePlanSettingQuery) Test.createStub(PJN_AllCarePlanSettingQuery.class, new PJN_AllCarePlanSettingMock());
        PJN_CarePlanPathListCtrl.allCarePlanSettingQuery = mockAllCarePlanSettingQuery;

        Test.startTest();
            Map<String, PJN_All_Care_Plan_Setting__mdt> actualAllCarePlanSettingsByProgramDeveloperName = PJN_CarePlanPathListCtrl.getAllCarePlanSettingsByProgramDeveloperName();
        Test.stopTest();

        System.assertEquals(false, actualAllCarePlanSettingsByProgramDeveloperName.isEmpty());
        System.assertEquals(1, actualAllCarePlanSettingsByProgramDeveloperName.size());
    }

    @isTest
    private static void getAllCarePlanSettingFieldsBySettingDeveloperName() {
        PJN_AllCarePlanFieldSettingQuery mockAllCarePlanFieldSettingQuery = (PJN_AllCarePlanFieldSettingQuery) Test.createStub(PJN_AllCarePlanFieldSettingQuery.class, new PJN_AllCarePlanFieldSettingMock());
        PJN_CarePlanPathListCtrl.allCarePlanFieldSettingQuery = mockAllCarePlanFieldSettingQuery;
        String expectedAllCarePlanSettingDeveloperName = 'PJN_Mocked_ALL_Care_Plan_Setting';
        List<String> allCarePlanSettingDeveloperNamesSet = new List<String> {
            expectedAllCarePlanSettingDeveloperName
        };

        Test.startTest();
            Map<String, List<PJN_All_Care_Plan_Setting_Field__mdt>> actualAllCarePlanSettingFieldsBySettingDeveloperName = PJN_CarePlanPathListCtrl.getAllCarePlanSettingFieldsBySettingDeveloperName(allCarePlanSettingDeveloperNamesSet);
        Test.stopTest();

        System.assertEquals(false, actualAllCarePlanSettingFieldsBySettingDeveloperName.isEmpty());
        System.assertEquals(1, actualAllCarePlanSettingFieldsBySettingDeveloperName.size());
        System.assertEquals(2, actualAllCarePlanSettingFieldsBySettingDeveloperName.get(expectedAllCarePlanSettingDeveloperName).size());
    }
}