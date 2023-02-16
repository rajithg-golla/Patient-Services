/**
* @author Mavens
* @description Test class for MVN_HubStatusExportHdlr
* @group hub-status-export
*/
@isTest
private class MVN_HubStatusExportHdlrTest {

    @testSetup
    static void setup() {
        Account patient = new Account (
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            FirstName = 'Patient',
            LastName = 'Test'
        );
        insert patient;
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'MVN_EVK',
            StartDate = Date.today()
        );
        insert program;
        Case carePlan = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Program__c = program.Id
        );
        insert carePlan;
    }

    @isTest
    static void testSetStatusDescriptionAndMilestoneActive() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c event = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Active',
            PJN_New_Therapy_Sub_Status__c = 'Treatment Confirmed'
        );
        Test.startTest();
            insert event;
        Test.stopTest();

        event = [SELECT MVN_Status_Description__c, MVN_Milestone__c FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'MyRare has confirmed that patient received treatment',
            event.MVN_Status_Description__c,
            'Wrong Active Status Description calculation'
        );
        System.assertEquals(
            'OB',
            event.MVN_Milestone__c,
            'Wrong Active Milestone calculation'
        );
    }

    @isTest
    static void testSetStatusDescriptionAndMilestonePending() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c event = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Pending',
            PJN_New_Therapy_Sub_Status__c = 'Prescriber Welcome Call Attempted'
        );
        Test.startTest();
            insert event;
        Test.stopTest();

        event = [SELECT MVN_Status_Description__c, MVN_Milestone__c FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'Welcome call attempt to prescriber',
            event.MVN_Status_Description__c,
            'Wrong Pending Status Description calculation'
        );
        System.assertEquals(
            'PE',
            event.MVN_Milestone__c,
            'Wrong Pending Milestone calculation'
        );
    }

    @isTest
    static void testSetStatusDescriptionAndMilestoneCancelled() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c event = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Cancelled',
            PJN_New_Therapy_Sub_Status__c = 'Patient Decision - Financial'
        );
        Test.startTest();
            insert event;
        Test.stopTest();

        event = [SELECT MVN_Status_Description__c, MVN_Milestone__c FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'Patient unable to afford out of pocket expense',
            event.MVN_Status_Description__c,
            'Wrong Cancelled Status Description calculation'
        );
        System.assertEquals(
            'FR',
            event.MVN_Milestone__c,
            'Wrong Cancelled Milestone calculation'
        );
    }

    @isTest
    static void testSetStatusDescriptionAndMilestoneDiscontinued() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c event = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Discontinued',
            PJN_New_Therapy_Sub_Status__c = 'Patient Off Therapy'
        );
        Test.startTest();
            insert event;
        Test.stopTest();

        event = [SELECT MVN_Status_Description__c, MVN_Milestone__c FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'Patient no longer in therapy',
            event.MVN_Status_Description__c,
            'Wrong Discontinued Status Description calculation'
        );
        System.assertEquals(
            'OB',
            event.MVN_Milestone__c,
            'Wrong Discontinued Milestone calculation'
        );
    }
}