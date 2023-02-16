/**
 * @author      Mavens
 * @group       CarePlan
 * @description Unit tests for PJN_NewCarePlanChildRecordCtrl
 */
@isTest
public with sharing class PJN_NewCarePlanChildRecordCtrlTest {

    private static final ID CAREPLAN_RECORDTYPEID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();

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

        Case careplan = new Case(
            RecordTypeId = CAREPLAN_RECORDTYPEID,
            Status = 'Test',
            Subject = 'Care Plan',
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Program_DeveloperName__c = 'PJN_Test_Program'
        );
        insert careplan;
    }

    @isTest
    private static void itShouldReturnNullObject() {
        SObject thisSObject;
        String errorMessage;

        Test.startTest();
        try {
            thisSObject = PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(null, null, null);
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(null, thisSObject);
        System.assert(String.isNotBlank(errorMessage));
        System.assert(errorMessage.contains('Something went wrong'));
    }

    @isTest
    private static void itShouldPopulatePrescriptionFields() {
        HealthCloudGA__EhrMedicationPrescription__c prescription;

        Case carePlan = [
            SELECT
                Id,
                AccountId,
                PJN_Physician__c
            FROM
                Case
            WHERE
                RecordTypeId = :CAREPLAN_RECORDTYPEID
            LIMIT 1
        ];

        Test.startTest();
        prescription = (HealthCloudGA__EhrMedicationPrescription__c) PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(carePlan.Id, 'HealthCloudGA__EhrMedicationPrescription__c', null);
        Test.stopTest();

        System.assertNotEquals(null, prescription);
        System.assertEquals(carePlan.Id, prescription.PJN_Care_Plan__c);
        System.assertEquals(careplan.AccountId, prescription.HealthCloudGA__Account__c);
        System.assertEquals(careplan.PJN_Physician__c, prescription.PJN_Physician__c);
    }

    @isTest
    private static void itShouldNOTPopulatePrescriptionFields() {
        HealthCloudGA__EhrMedicationPrescription__c prescription;

        Test.startTest();
        prescription = (HealthCloudGA__EhrMedicationPrescription__c) PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(null, 'HealthCloudGA__EhrMedicationPrescription__c', null);
        Test.stopTest();

        System.assertNotEquals(null, prescription);
        System.assertEquals(null, prescription.PJN_Care_Plan__c);
        System.assertEquals(null, prescription.HealthCloudGA__Account__c);
        System.assertEquals(null, prescription.PJN_Physician__c);
    }

    @isTest
    private static void itShouldNOTPopulateContactInfoFields() {
        PJN_Contact_Information__c ci;

        Case carePlan = [
            SELECT
                Id,
                AccountId,
                PJN_Physician__c
            FROM
                Case
            WHERE
                RecordTypeId = :CAREPLAN_RECORDTYPEID
            LIMIT 1
        ];

        Test.startTest();
        ci = (PJN_Contact_Information__c) PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(carePlan.Id, 'PJN_Contact_Information__c', null);
        Test.stopTest();

        System.assertNotEquals(null, ci);
        System.assertNotEquals(carePlan.AccountId, ci.PJN_Account__c);
    }

    @isTest
    private static void itShouldPopulateMemberPlanFields() {
        PJN_Member_Plan__c memberPlan;

        Case carePlan = [
            SELECT
                Id,
                AccountId
            FROM
                Case
            WHERE
                RecordTypeId = :CAREPLAN_RECORDTYPEID
            LIMIT 1
        ];

        Test.startTest();
        memberPlan = (PJN_Member_Plan__c) PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(carePlan.Id, 'PJN_Member_Plan__c', null);
        Test.stopTest();

        System.assertNotEquals(null, memberPlan);
        System.assertEquals(carePlan.Id, memberPlan.PJN_Care_Plan__c);
        System.assertEquals(careplan.AccountId, memberPlan.PJN_Patient__c);
    }

    @isTest
    private static void itShouldPopulateConsentFields() {
        PJN_Contact_Point_Type_Consent__c consent;

        Case carePlan = [
            SELECT
                Id,
                AccountId
            FROM
                Case
            WHERE
                RecordTypeId = :CAREPLAN_RECORDTYPEID
            LIMIT 1
        ];

        Test.startTest();
        consent = (PJN_Contact_Point_Type_Consent__c) PJN_NewCarePlanChildRecordCtrl.getCarePlanChildMapped(carePlan.Id, 'PJN_Contact_Point_Type_Consent__c', null);
        Test.stopTest();

        System.assertNotEquals(null, consent);
        System.assertEquals(carePlan.Id, consent.PJN_Care_Plan__c);
        System.assertEquals(careplan.AccountId, consent.PJN_Patient__c);
    }
}