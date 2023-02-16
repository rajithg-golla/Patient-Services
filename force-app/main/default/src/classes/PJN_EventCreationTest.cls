/**
* @author Mavens
* @date May 2019
* @description Test class for PJN_EventCreation
* @group event-triggers
*/
@isTest
private class PJN_EventCreationTest {

    static Map<String, RecordTypeInfo> acctRecTypes = SObjectType.Account.getRecordTypeInfosByDeveloperName();

    @TestSetup
    static void makeData(){

        Account patient = new Account(
            RecordTypeId = acctRecTypes.get('PJN_Patient').getRecordTypeId(),
            LastName = 'Patient Test'
        );
        Account patientUpdated = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Patient Updated Test'
        );
        Account physician = new Account(
            RecordTypeId = acctRecTypes.get('PJN_Physician').getRecordTypeId(),
            LastName = 'Physician Test'
        );
        Account physicianUpdated = new Account(
            RecordTypeId = acctRecTypes.get('PJN_Physician').getRecordTypeId(),
            LastName = 'Physician Updated Test'
        );

        insert new List<Account> {patient, patientUpdated, physician, physicianUpdated};

        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan Case',
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id
        );
        insert carePlan;
    }

    @isTest
    private static void testUpdatePhysicianCreateEvent() {
        Case carePlan = [SELECT Id, AccountId FROM Case LIMIT 1];
        Account patient = getAccount('Patient Test');
        Account physician = getAccount('Physician Test');
        Account physicianUpdated = getAccount('Physician Updated Test');

        Test.startTest();
            carePlan.PJN_Physician__c = physicianUpdated.Id;
            update carePlan;
        Test.stopTest();
        PJN_Event__c event = [
            SELECT
                RecordTypeId,
                PJN_Patient__c,
                PJN_New_Physician__c,
                PJN_Previous_Physician__c
            FROM
                PJN_Event__c
            WHERE
                PJN_Case__c = :carePlan.Id
        ];
        Id physicianChangeRecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('PJN_Physician_Change').getRecordTypeId();
        System.assertEquals(physicianChangeRecordTypeId, event.RecordTypeId);
        System.assertEquals(patient.Id, event.PJN_Patient__c);
        System.assertEquals(physicianUpdated.Id, event.PJN_New_Physician__c);
        System.assertEquals(physician.Id, event.PJN_Previous_Physician__c);
    }

    @isTest
    private static void testUpdatePatientDoNotCreateEvent() {
        Case carePlan = [SELECT Id, AccountId FROM Case LIMIT 1];
        Account patientUpdated = getAccount('Patient Updated Test');

        Test.startTest();
            carePlan.AccountId = patientUpdated.Id;
            update carePlan;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM PJN_Event__c WHERE PJN_Case__c = :carePlan.Id]);
    }

    private static Account getAccount(String lastName) {
        for (Account acct : [SELECT Id, LastName FROM Account]) {
            if  (acct.LastName == lastName) {
                return acct;
            }
        }
        return null;
    }
}