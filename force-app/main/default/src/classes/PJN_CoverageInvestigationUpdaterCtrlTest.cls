/**
 * @author      Mavens
 * @date        1/2021
 * @description Unit tests for pjnCoverageInvestigationUpdater lwc
 * @group       CoverageInvestigation
 */

@isTest
public class PJN_CoverageInvestigationUpdaterCtrlTest {

    @TestSetup
    static void makeData(){
        Account patient = new Account(
            LastName = 'Patient Test',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId()
        );
        insert patient;

        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Care Plan Case',
                'AccountId' => patient.Id,
                'PJN_Therapy_Status__c' => 'Active'
            }
        );

        PJN_Coverage_Investigation__c investigation = new PJN_Coverage_Investigation__c(
            PJN_Care_Plan__c = carePlan.Id
        );
        insert investigation;

        PJN_Member_Plan__c plan = new PJN_Member_Plan__c(
            PJN_Care_Plan__c = carePlan.Id
        );
        insert plan;

        insert new PJN_Coverage_Investigation_Item__c (
            PJN_Coverage_Investigation__c = investigation.Id,
            PJN_Member_Plan__c = plan.Id
        );

        insert new PJN_Prior_Authorization__c(
            PJN_Member_Plan__c = plan.Id,
            PJN_Coverage_Investigation__c = investigation.Id
        );

        insert new PJN_Assistance_Program__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Coverage_Investigation__c = investigation.Id
        );
    }

    @isTest
    private static void itShouldGetTables() {
        PJN_Coverage_Investigation__c investigation = [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];

        AuraHandledException badObjectException;

        Test.startTest();
        PJN_DataTable memberPlanDataTable = PJN_CoverageInvestigationUpdaterCtrl.getTable(investigation.Id, 'PJN_Member_Plan__c');
        PJN_DataTable priorAuthDataTable = PJN_CoverageInvestigationUpdaterCtrl.getTable(investigation.Id, 'PJN_Prior_Authorization__c');
        PJN_DataTable assistProgDataTable = PJN_CoverageInvestigationUpdaterCtrl.getTable(investigation.Id, 'PJN_Assistance_Program__c');
        try {
            PJN_CoverageInvestigationUpdaterCtrl.getTable(investigation.Id, 'bad_object');
        } catch (AuraHandledException ex) {
            badObjectException = ex;
        }
        Test.stopTest();

        System.assertEquals(1, memberPlanDataTable.data.size());
        System.assertNotEquals(null, memberPlanDataTable.columns);

        System.assertEquals(1, priorAuthDataTable.data.size());
        System.assertNotEquals(null, priorAuthDataTable.columns);

        System.assertEquals(1, assistProgDataTable.data.size());
        System.assertNotEquals(null, assistProgDataTable.columns);

        System.assertNotEquals(null, badObjectException);
    }

    @isTest
    private static void itShouldGetFields() {
        AuraHandledException badObjectException;

        Test.startTest();
        List<PJN_CoverageInvestigationUpdaterCtrl.InputField> fields =  PJN_CoverageInvestigationUpdaterCtrl.getFields('PJN_Member_Plan__c');
        try {
            PJN_CoverageInvestigationUpdaterCtrl.getFields('bad_object');
        } catch (AuraHandledException ex) {
            badObjectException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(0, fields.size());
        System.assertNotEquals(null, badObjectException);
    }

    @isTest
    private static void itShouldSubmit() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.developerName = 'CarePlan' LIMIT 1];
        PJN_Coverage_Investigation__c investigation = [SELECT Id, PJN_Status__c FROM PJN_Coverage_Investigation__c LIMIT 1];
        investigation.PJN_Status__c = 'Completed';
        Map<String, SObject> data = new Map<String, SObject> {
            'PJN_Coverage_Investigation__c' => investigation,
            'Case' => new Case(Subject = 'Test', PJN_Coverage_Investigation__c = investigation.Id),
            'PJN_Event__c' => new PJN_Event__c(PJN_Coverage_Investigation__c = investigation.Id)
        };

        Test.startTest();
        PJN_CoverageInvestigationUpdaterCtrl.submit(data);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM PJN_Coverage_Investigation__c WHERE Id = :investigation.Id AND PJN_Status__c = 'Completed']);
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE ParentId = :carePlan.Id AND RecordTypeId = :activityRTId]);
    }

    @isTest
    private static void itShouldGetTherapyAccessRecordTypeId() {
        System.assertEquals(
            PJN_Event__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Access').getRecordTypeId(),
            PJN_CoverageInvestigationUpdaterCtrl.getTherapyAccessRecTypeId()
        );
    }

    @isTest
    private static void itShouldThrowAuraExceptionOnBadSubmit() {
        AuraHandledException badSubmitException;

        Test.startTest();
        try {
            PJN_CoverageInvestigationUpdaterCtrl.submit(new Map<String, SObject>{'PJN_Coverage_Investigation__c' => new PJN_Coverage_Investigation__c()});
        } catch (AuraHandledException ex) {
            badSubmitException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, badSubmitException);
    }
}