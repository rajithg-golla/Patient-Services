/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanCaseWrapper
 */
@isTest
public class PJN_CarePlanFieldsMappingTest {

    static Map<String, RecordTypeInfo> acctRecTypes = SObjectType.Account.getRecordTypeInfosByDeveloperName();

    @TestSetup
    static void makeData(){
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Test Patient'
        );
        Account physician = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            LastName = 'Test Physician'
        );
        insert new List<Account> {patient, physician};
        Test.startTest();
        Case careplan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan',
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Program_DeveloperName__c = 'PJN_Test_Program'
        );
        insert careplan;
        Test.stopTest();
    }

    @isTest
    private static void handleCareplanFieldsMappingForPrescription() {
        Case carePlan = [SELECT Id, AccountId, PJN_Program_DeveloperName__c, PJN_Physician__c FROM Case LIMIT 1];

        HealthCloudGA__EhrMedicationPrescription__c prescriptionToInsert = new HealthCloudGA__EhrMedicationPrescription__c(
            PJN_Care_Plan__c = careplan.Id
        );

        Test.startTest();
            Database.SaveResult actualSaveResult = Database.insert(prescriptionToInsert);
        Test.stopTest();

        HealthCloudGA__EhrMedicationPrescription__c actualPrescription = [
            SELECT
                Id,
                PJN_Care_Plan__c,
                PJN_Program_DeveloperName__c,
                PJN_Creation_UUID__c,
                HealthCloudGA__Account__c,
                PJN_Physician__c
            FROM
                HealthCloudGA__EhrMedicationPrescription__c
            WHERE
                Id = :prescriptionToInsert.Id
        ];

        System.assertEquals(true, actualSaveResult.isSuccess());
        System.assertEquals(careplan.Id, actualPrescription.PJN_Care_Plan__c);
        System.assertEquals(careplan.PJN_Program_DeveloperName__c, actualPrescription.PJN_Program_DeveloperName__c);
        System.assertNotEquals(null, actualPrescription.PJN_Creation_UUID__c);
        System.assertEquals(careplan.AccountId, actualPrescription.HealthCloudGA__Account__c);
        System.assertEquals(careplan.PJN_Physician__c, actualPrescription.PJN_Physician__c);
    }

    @isTest
    private static void handleCareplanFieldsMappingForMemberPlan() {
        Case carePlan = [SELECT Id, AccountId FROM Case LIMIT 1];

        PJN_Member_Plan__c memberPlanToInsert = new PJN_Member_Plan__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Set_as_Active__c = true,
            PJN_Coverage_Order__c = 'Primary'
        );

        Test.startTest();
            Database.SaveResult actualSaveResult = Database.insert(memberPlanToInsert);
        Test.stopTest();

        PJN_Member_Plan__c actualMemberPlan = [
            SELECT
                Id,
                PJN_Care_Plan__c,
                PJN_Creation_UUID__c,
                PJN_Patient__c
            FROM
                PJN_Member_Plan__c
            WHERE
                Id = :memberPlanToInsert.Id
        ];

        System.assertEquals(true, actualSaveResult.isSuccess());
        System.assertEquals(careplan.Id, actualMemberPlan.PJN_Care_Plan__c);
        System.assertNotEquals(null, actualMemberPlan.PJN_Creation_UUID__c);
        System.assertEquals(careplan.AccountId, actualMemberPlan.PJN_Patient__c);
    }

    @isTest
    private static void handleCareplanFieldsMappingForConsent() {
        Case carePlan = [SELECT Id, AccountId FROM Case LIMIT 1];

        PJN_Contact_Point_Type_Consent__c consentToInsert = new PJN_Contact_Point_Type_Consent__c(
            PJN_Care_Plan__c = careplan.Id
        );

        Test.startTest();
            Database.SaveResult actualSaveResult = Database.insert(consentToInsert);
        Test.stopTest();

        PJN_Contact_Point_Type_Consent__c actualConsent = [
            SELECT
                Id,
                PJN_Care_Plan__c,
                PJN_Creation_UUID__c,
                PJN_Patient__c
            FROM
                PJN_Contact_Point_Type_Consent__c
            WHERE
                Id = :consentToInsert.Id
        ];

        System.assertEquals(true, actualSaveResult.isSuccess());
        System.assertEquals(careplan.Id, actualConsent.PJN_Care_Plan__c);
        System.assertNotEquals(null, actualConsent.PJN_Creation_UUID__c);
        System.assertEquals(careplan.AccountId, actualConsent.PJN_Patient__c);
    }
}