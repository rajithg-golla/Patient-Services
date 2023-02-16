/**
 * @author      Mavens
 * @date        11/2019
 * @description Tests for PJN_AccountSearchCarePlanSelectorCtrl
 * @group       AccountSearch
 */
@isTest(isParallel=true)
private class PJN_AccountSearchCarePlanSelectCtrlTest {

    @testSetup private static void setup() {
        Account patient = new Account(
            LastName = 'Patient Test',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        insert patient;

        List<Case> caseList = new List<Case>();
        caseList.add(
            new Case(
                RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                Status = 'Test',
                Subject = 'Main Care Plan'
            )
        );
        caseList.add(
            new Case(
                RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                Status = 'Test',
                Subject = 'Activity Case',
                AccountId = patient.Id
            )
        );
        insert caseList;
    }

    @isTest
    static void testGetCarePlans() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        carePlan.AccountId = patient.Id;
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case availablePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Available Care Plan'
            }
        );
        availablePlan.AccountId = patient.Id;

        List<Case> plans = new List<Case>();
        plans.add(carePlan);
        plans.add(availablePlan);
        update plans;

        Test.startTest();
        PJN_CarePlanSelectorWrapper availablePlans = PJN_AccountSearchCarePlanSelectorCtrl.getCarePlans(patient.Id, carePlan.Id);
        Test.stopTest();

        System.assertEquals(1, availablePlans.carePlanWrapperList.size(), 'Should only be one available plan');
        System.assertEquals('Available Care Plan', availablePlans.carePlanWrapperList[0].carePlanRecord.subject,
            'Should not obtain the same plan as the one provided');
    }

    @isTest static void testSetPatientCarePlan() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Test.startTest();
        Case updatedActivity =
            PJN_AccountSearchCarePlanSelectorCtrl.setPatientCarePlan(activity.Id, carePlan.Id);
        Test.stopTest();

        System.assertNotEquals(null, updatedActivity, 'The activity should have been returned');

        System.assertEquals(activity.Id, updatedActivity.Id,
            'The updated activity should have been returned');

        System.assertEquals(carePlan.Id, updatedActivity.ParentId,
            'Activity should have care plan as parent case');
    }
}