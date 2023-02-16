/**
 * @author      Mavens
 * @date        11/2020
 * @description Unit tests for PJN_ActiveCoverageInvestigatnHdlr
 * @group       CoverageInvestigation
 */
@isTest
public with sharing class PJN_ActiveCoverageInvestigatnHdlrTest {

    private static final Integer DATA_SIZE = 200;

    @TestSetup
    static void makeData(){
        List<Account> patients = new List<Account>();
        for (Integer i=0; i<200; i++) {
            patients.add(
                new Account(
                    LastName = 'Patient' + i,
                    FirstName = 'Test',
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
                )
            );
        }

        insert patients;

        List<Case> carePlans = new List<Case>();
        for (Account patient : patients) {
            carePlans.add(
                new Case (
                    AccountId = patient.Id,
                    RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
                )
            );
        }
        insert carePlans;

        // query for all settings for this object and mock the ones we need turned on
        List<PJN_Trigger_Handler_Setting__mdt> settings = new List<PJN_Trigger_Handler_Setting__mdt>();
        List<PJN_Trigger_Handler_Setting__mdt> allObjSettings = [
            SELECT PJN_Class__c, PJN_Event__c, PJN_Active__c
            FROM PJN_Trigger_Handler_Setting__mdt
            WHERE PJN_SObject_API_Name__c = 'PJN_Coverage_Investigation__c'
            ORDER BY PJN_Order__c ASC
        ];

        // already active? keep it. If not active but is the class we care about then treat as active
        for (PJN_Trigger_Handler_Setting__mdt setting : allObjSettings) {
            if (setting.PJN_Active__c || setting.PJN_Class__c == 'PJN_ActiveCoverageInvestigationHdlr') {
                settings.add(setting);
            }
        }

        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            PJN_Coverage_Investigation__c.getSObjectType(),
            settings
        );
    }

    @isTest
    private static void itShouldSetCoverageInvestigationAsActiveOnInsert() {
        List<Case> carePlans = [SELECT Id FROM Case];

        List<PJN_Coverage_Investigation__c> investigations = new List<PJN_Coverage_Investigation__c>();
        for (Case carePlan : carePlans) {
            investigations.add(
                new PJN_Coverage_Investigation__c(
                    PJN_Care_Plan__c = carePlan.Id,
                    PJN_Set_as_Active__c = true
                )
            );
        }

        Test.startTest();
        insert investigations;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE PJN_Active_Coverage_Investigation__c != null]);
        System.assertEquals(200, [
            SELECT COUNT()
            FROM PJN_Coverage_Investigation__c
            WHERE PJN_Is_Active_Investigation__c = true
            AND PJN_Set_as_Active__c = false
        ]);
    }

    @isTest
    private static void itShouldSetCoverageInvestigationAsActiveOnUpdate() {
        List<Case> carePlans = [SELECT Id FROM Case];

        List<PJN_Coverage_Investigation__c> investigations = new List<PJN_Coverage_Investigation__c>();
        for (Case carePlan : carePlans) {
            investigations.add(
                new PJN_Coverage_Investigation__c(
                    PJN_Care_Plan__c = carePlan.Id,
                    PJN_Set_as_Active__c = false
                )
            );
        }

        insert investigations;

        Test.startTest();
        for (PJN_Coverage_Investigation__c investigation : investigations) {
            investigation.PJN_Set_as_Active__c = true;
        }
        update investigations;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE PJN_Active_Coverage_Investigation__c != null]);
        System.assertEquals(200, [
            SELECT COUNT()
            FROM PJN_Coverage_Investigation__c
            WHERE PJN_Is_Active_Investigation__c = true
            AND PJN_Set_as_Active__c = false
        ]);
    }
}