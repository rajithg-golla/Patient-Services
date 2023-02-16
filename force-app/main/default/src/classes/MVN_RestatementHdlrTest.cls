/**
* @author Mavens
* @description Test class for MVN_RestatementHdlr
* @group hub-status-export
*/
@isTest
private class MVN_RestatementHdlrTest {

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
    static void testNotARestatement() {
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

        event = [SELECT MVN_Restatement__c FROM PJN_Event__c WHERE Id = :event.Id];
        System.assertEquals(
            'N',
            event.MVN_Restatement__c,
            'Restatement field should not be set for non-restatement RT Events'
        );
    }

    @isTest
    static void testSuccessRestatement() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.Name='CarePlan' LIMIT 1];
        PJN_Event__c eventToBeRestated = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Active',
            PJN_New_Therapy_Sub_Status__c = 'Treatment Confirmed',
            MVN_HUB_Code__c = 'REGENERONHUB',
            MVN_Access_Type__c = 'Commercial',
            MVN_Referral_Source__c = 'AssistRX',
            MVN_Referral_Date__c = Date.today()
        );
        insert eventToBeRestated;
        List<PJN_Event__c> eventList = new List<PJN_Event__c>();
        eventList.add(new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Pending',
            PJN_New_Therapy_Sub_Status__c = 'Prescriber Welcome Call Attempted',
            MVN_HUB_Code__c = 'REGENERONHUB',
            MVN_Access_Type__c = 'Commercial',
            MVN_Referral_Source__c = 'AssistRX',
            MVN_Referral_Date__c = Date.today()
        ));
        eventList.add(new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Cancelled',
            PJN_New_Therapy_Sub_Status__c = 'Patient Decision - Financial',
            MVN_HUB_Code__c = 'REGENERONHUB',
            MVN_Access_Type__c = 'Commercial',
            MVN_Referral_Source__c = 'AssistRX',
            MVN_Referral_Date__c = Date.today()
        ));
        insert eventList;
        PJN_Event__c yesterdayEvent = new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_New_Therapy_Status__c = 'Cancelled',
            PJN_New_Therapy_Sub_Status__c = 'Patient Decision - Financial',
            MVN_HUB_Code__c = 'REGENERONHUB',
            MVN_Access_Type__c = 'Commercial',
            MVN_Referral_Source__c = 'AssistRX',
            MVN_Referral_Date__c = Date.today()
        );
        insert yesterdayEvent;
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(yesterdayEvent.Id, yesterday);

        Test.startTest();
            update new PJN_Event__c(
                RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                        .get('MVN_Therapy_Status_Restatement').getRecordTypeId(),
                Id = eventToBeRestated.Id,
                PJN_SP_Patient_ID__c = 'SP12345',
                MVN_Patient_Id__c = 'CRM12345',
                PJN_Patient_Gender__c = 'Male',
                MVN_ICD_10_CM_Diagnosis_Code__c = 'E78.01',
                PJN_Physician_Last_Name__c = 'Smith',
                PJN_Physician_First_Name__c = 'Lauren',
                MVN_Copay_BIN__c = '12345',
                MVN_Copay_PCN__c = '12345',
                MVN_Restatement_Start_Date__c = Date.today(),
                MVN_Restatement_End_Date__c = Date.today()
            );
        Test.stopTest();

        eventList = [
            SELECT
                PJN_SP_Patient_ID__c,
                MVN_Patient_Id__c,
                PJN_Patient_Gender__c,
                MVN_ICD_10_CM_Diagnosis_Code__c,
                PJN_Physician_Last_Name__c,
                PJN_Physician_First_Name__c,
                MVN_Copay_BIN__c,
                MVN_Copay_PCN__c,
                MVN_Restatement__c
            FROM
                PJN_Event__c
        ];
        
        for (PJN_Event__c event : eventList) {
            if (event.Id == yesterdayEvent.Id) {
                System.assertEquals(null,event.PJN_SP_Patient_ID__c);
                System.assertEquals(null,event.MVN_Patient_Id__c);
                System.assertEquals(null,event.PJN_Patient_Gender__c);
                System.assertEquals(null,event.MVN_ICD_10_CM_Diagnosis_Code__c);
                System.assertEquals(null,event.PJN_Physician_Last_Name__c);
                System.assertEquals(null,event.PJN_Physician_First_Name__c);
                System.assertEquals(null,event.MVN_Copay_BIN__c);
                System.assertEquals(null,event.MVN_Copay_PCN__c);
                System.assertEquals('N',event.MVN_Restatement__c);
            } else {
                System.assertEquals('SP12345',event.PJN_SP_Patient_ID__c);
                System.assertEquals('CRM12345',event.MVN_Patient_Id__c);
                System.assertEquals('Male',event.PJN_Patient_Gender__c);
                System.assertEquals('E78.01',event.MVN_ICD_10_CM_Diagnosis_Code__c);
                System.assertEquals('Smith',event.PJN_Physician_Last_Name__c);
                System.assertEquals('Lauren',event.PJN_Physician_First_Name__c);
                System.assertEquals('12345',event.MVN_Copay_BIN__c);
                System.assertEquals('12345',event.MVN_Copay_PCN__c);
                System.assertEquals('Y',event.MVN_Restatement__c);
            }
        }
    }
}