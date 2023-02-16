/*
 * @description Unit tests for PJN_MedicalHistoryCtrl
 * @author      Mavens
 * @Created     October 2019
 */

@isTest
public class PJN_MedicalHistoryCtrlTest {

    private static final Id PATIENT_RECORDTYPE_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
    private static final Id CAREPLAN_RECORDTYPE_ID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();

    private static Id MEDICAL_RECORDTYPE_ID_1 = SObjectType.PJN_Medical_History__c.getRecordTypeInfosByDeveloperName().get('PJN_Metric').getRecordTypeId();
    private static Id MEDICAL_RECORDTYPE_ID_2 = SObjectType.PJN_Medical_History__c.getRecordTypeInfosByDeveloperName().get('PJN_Allergy').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Account patient = new Account(
            RecordTypeId = PATIENT_RECORDTYPE_ID,
            LastName = 'Patient'
        );
        insert patient;

        createCarePlanAndMedicalHistory(patient.Id);
    }

    private static Case createCarePlanAndMedicalHistory(Id patientId) {
        Case carePlan = new Case(
            AccountId = patientId,
            RecordTypeId = CAREPLAN_RECORDTYPE_ID
        );
        insert carePlan;

        List<PJN_Medical_History__c> medHistory = new List<PJN_Medical_History__c>();

        for (Integer i=0; i<10; i++) {
            medHistory.add(
                new PJN_Medical_History__c(
                    PJN_Patient__c = patientId,
                    PJN_Care_Plan__c = carePlan.Id,
                    RecordTypeId = MEDICAL_RECORDTYPE_ID_1
                )
            );
        }
        medHistory.add(
            new PJN_Medical_History__c(
                PJN_Patient__c = patientId,
                PJN_Care_Plan__c = carePlan.Id,
                RecordTypeId = MEDICAL_RECORDTYPE_ID_2
            )
        );

        insert medHistory;

        return carePlan;
    }

    @isTest
    private static void itShouldReturnCurrentMedicalHistoryRecordsForARecordType() {
        Case carePlan = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        System.assertEquals(10, PJN_MedicalHistoryCtrl.getMedicalHistory(carePlan.Id, MEDICAL_RECORDTYPE_ID_1, false).size());
        Test.stopTest();
    }


    @isTest
    private static void itShouldReturnAllMedicalHistoryRecordsForARecordType() {
        Case carePlan = [SELECT Id, AccountId FROM Case LIMIT 1];

        carePlan = createCarePlanAndMedicalHistory(carePlan.AccountId);

        Test.startTest();
        System.assertEquals(20, PJN_MedicalHistoryCtrl.getMedicalHistory(carePlan.Id, MEDICAL_RECORDTYPE_ID_1, true).size());
        Test.stopTest();
    }

    @isTest
    private static void itShouldReturnTheMetricRecordTypeId() {
        Id expectedRecordTypeId = SObjectType.PJN_Medical_History__c
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Metric')
            .getRecordTypeId();

        System.assertEquals(expectedRecordTypeId, PJN_MedicalHistoryCtrl.getMetricRecTypeId());
    }
}