/**
* @author Mavens
* @description Test class for PJN_ClearMemberPlanFields
* @group       CarePlan Fields Mapping
*/
@isTest
private class PJN_ClearMemberPlanFieldsTest {

    @TestSetup
    static void makeData(){
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;

        Account patient = new Account (
            LastName = 'Patient',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        insert patient;

        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Program__c = program.Id
        );
        insert carePlan;

        List<PJN_Member_Plan__c> memberPlanList = new List<PJN_Member_Plan__c>();
        memberPlanList.add(new PJN_Member_Plan__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Expiration_Date__c = Date.today(),
            PJN_Coverage_Order__c = 'Primary'
        ));
        memberPlanList.add(new PJN_Member_Plan__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Expiration_Date__c = Date.today(),
            PJN_Coverage_Order__c = 'Secondary'
        ));
        memberPlanList.add(new PJN_Member_Plan__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Expiration_Date__c = Date.today(),
            PJN_Coverage_Order__c = 'Tertiary'
        ));
        insert memberPlanList;
    }

    @isTest
    private static void testUpdatePrimaryMemberPlan() {
        PJN_Member_Plan__c memberPlan = [
            SELECT Id FROM PJN_Member_Plan__c WHERE PJN_Coverage_Order__c = 'Primary'
        ];
        Test.startTest();
            memberPlan.PJN_Coverage_Order__c = 'Secondary';
            memberPlan.PJN_Set_as_Active__c = true;
            update memberPlan;
        Test.stopTest();

        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [
            SELECT PJN_Primary_Member_Plan__c FROM Case WHERE RecordTypeId = :carePlanRecordTypeId
        ];
        System.assertEquals(null, carePlan.PJN_Primary_Member_Plan__c, 'Primary Member Plan Lookup has not been cleared up');
    }

    @isTest
    private static void testUpdateSecondaryMemberPlan() {
        PJN_Member_Plan__c memberPlan = [
            SELECT Id FROM PJN_Member_Plan__c WHERE PJN_Coverage_Order__c = 'Secondary'
        ];
        Test.startTest();
            memberPlan.PJN_Coverage_Order__c = 'Primary';
            memberPlan.PJN_Set_as_Active__c = true;
            update memberPlan;
        Test.stopTest();

        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [
            SELECT PJN_Secondary_Member_Plan__c FROM Case WHERE RecordTypeId = :carePlanRecordTypeId
        ];
        System.assertEquals(null, carePlan.PJN_Secondary_Member_Plan__c, 'Secondary Member Plan Lookup has not been cleared up');
    }

    @isTest
    private static void testUpdateTertiaryMemberPlan() {
        PJN_Member_Plan__c memberPlan = [
            SELECT Id FROM PJN_Member_Plan__c WHERE PJN_Coverage_Order__c = 'Tertiary'
        ];
        Test.startTest();
            memberPlan.PJN_Coverage_Order__c = 'Secondary';
            memberPlan.PJN_Set_as_Active__c = true;
            update memberPlan;
        Test.stopTest();

        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [
            SELECT PJN_Tertiary_Member_Plan__c FROM Case WHERE RecordTypeId = :carePlanRecordTypeId
        ];
        System.assertEquals(null, carePlan.PJN_Tertiary_Member_Plan__c, 'Tertiary Member Plan Lookup has not been cleared up');
    }
}