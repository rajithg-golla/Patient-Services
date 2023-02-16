/**
* @author Mavens
* @description Test class for MVN_RestatementRTUpdateCtr
* @group hub-status-export
*/
@isTest
private class MVN_RestatementRTUpdateCtrlTest {

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
    static void testSwitchRTSuccess() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c event = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Active',
            PJN_New_Therapy_Sub_Status__c = 'Treatment Confirmed'
        );
        insert event;

        Test.startTest();
            MVN_RestatementRTUpdateCtrl.switchRT(event.Id);
        Test.stopTest();

        event = [SELECT RecordType.DeveloperName FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'MVN_Therapy_Status_Restatement',
            event.RecordType.DeveloperName,
            'Error switching RT to Restatment RT'
        );
    }

    @isTest
    static void testSwitchRTException() {
        Test.startTest();
            try {
                MVN_RestatementRTUpdateCtrl.switchRT('001');
            } catch (Exception exc) {
                System.assert(exc!=null);
            }
        Test.stopTest();
    }
}