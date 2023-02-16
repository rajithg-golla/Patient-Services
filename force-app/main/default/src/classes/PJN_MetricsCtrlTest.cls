/*
 * @description Unit tests for PJN_MetricsCtrl
 * @author      Mavens
 * @Created     October 2019
 */
 @isTest
public class PJN_MetricsCtrlTest {

    private static final Integer CAREPLAN_AMOUNT = 2;

    @TestSetup
    static void makeData(){
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Patient'
        );
        insert patient;

        List<Case> carePlans = new List<Case>();

        for (Integer carePlanCount = 0; carePlanCount < CAREPLAN_AMOUNT; carePlanCount++) {
            carePlans.add(
                        new Case(
                    AccountId = patient.Id,
                    RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
                )
            );
        }

        insert carePlans;

        List<PJN_Metric_Group__c> metricGroups = new List<PJN_Metric_Group__c>{
            new PJN_Metric_Group__c(Name = 'Alpha', PJN_External_Id__c = 'Alpha'),
            new PJN_Metric_Group__c(Name = 'Beta', PJN_External_Id__c = 'Beta', PJN_Active__c = false),
            new PJN_Metric_Group__c(Name = 'Gamma', PJN_External_Id__c = 'Gamma'),
            new PJN_Metric_Group__c(Name = 'Delta', PJN_External_Id__c = 'Delta')
        };
        insert metricGroups;

        Id alphaGroupId = metricGroups[0].Id;
        List<PJN_Metric_Type__c> metricTypes = new List<PJN_Metric_Type__c>{
            new PJN_Metric_Type__c(Name='Group 1', PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Number', PJN_External_Id__c='Group 1'),
            new PJN_Metric_Type__c(Name='Group 2', PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Number', PJN_External_Id__c='Group 2'),
            new PJN_Metric_Type__c(Name='Group 3', PJN_Active__c=false, PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Number', PJN_External_Id__c='Group 3'),
            new PJN_Metric_Type__c(Name='Group 5', PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Number', PJN_External_Id__c='Group 5'),
            new PJN_Metric_Type__c(Name='Group 4', PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Number', PJN_External_Id__c='Group 4'),
            new PJN_Metric_Type__c(Name='Group 6', PJN_Metric_Group__c=alphaGroupId, PJN_Type__c='Picklist', PJN_External_Id__c='Group 6')
        };
        insert metricTypes;

        Id metricTypeId = metricTypes[5].Id;
        List<PJN_Metric_Type_Option__c> options = new List<PJN_Metric_Type_Option__c> {
            new PJN_Metric_Type_Option__c(Name='Option 3', PJN_Metric_Type__c=metricTypeId, PJN_Order__c=3),
            new PJN_Metric_Type_Option__c(Name='Option 2', PJN_Metric_Type__c=metricTypeId, PJN_Order__c=2),
            new PJN_Metric_Type_Option__c(Name='Option 1', PJN_Metric_Type__c=metricTypeId, PJN_Order__c=1)
        };
        insert options;

        Id metricRecType = SObjectType.PJN_Medical_History__c.getRecordTypeInfosByDeveloperName().get('PJN_Metric').getRecordTypeId();

        List<PJN_Medical_History__c> medHistory = new List<PJN_Medical_History__c>();

        for (Integer medHistoryCount = 0; medHistoryCount < CAREPLAN_AMOUNT; medHistoryCount++) {
            PJN_Medical_History__c medHistPrototype = new PJN_Medical_History__c(
                RecordTypeId=metricRecType,
                PJN_Patient__c=patient.Id,
                PJN_Care_Plan__c=carePlans[medHistoryCount].Id,
                PJN_Metric_Type__c=metricTypeId
            );
            medHistory.add(populateMedHistory(medHistPrototype, Date.today().addDays(-4), 'Option 4'));
            medHistory.add(populateMedHistory(medHistPrototype, Date.today().addDays(-3), 'Option 1'));
            medHistory.add(populateMedHistory(medHistPrototype, Date.today().addDays(-2), 'Option 3'));
            medHistory.add(populateMedHistory(medHistPrototype, Date.today().addDays(-1), 'Option 2'));
            medHistory.add(
                new PJN_Medical_History__c(
                    RecordTypeId=metricRecType,
                    PJN_Patient__c=patient.Id,
                    PJN_Care_Plan__c=carePlans[medHistoryCount].Id,
                    PJN_Metric_Type__c=metricTypes[0].Id,
                    PJN_Value__c='42',
                    PJN_Date__c=Date.today()
                )
            );
        }

        insert medHistory;
    }

    /* Helper method */
    private static PJN_Medical_History__c populateMedHistory(PJN_Medical_History__c mh, Date d, String value) {
        PJN_Medical_History__c mhClone = mh.clone(false, false, false, false);
        mhClone.PJN_Date__c = d;
        mhClone.PJN_Value__c = value;

        return mhClone;
    }

    @isTest
    private static void itShouldReturnActiveMetricGroups() {
        Test.startTest();
        List<PJN_Metric_Group__c> metricGroups = PJN_MetricsCtrl.getMetricGroups();
        Test.stopTest();

        System.assertEquals(3, metricGroups.size());
        System.assertEquals('Gamma', metricGroups[2].Name);
    }

    @isTest
    private static void itShouldReturnMetricCountsByGroupShowingAll() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;

        Test.startTest();
        Map<Id, Integer> metricCountsByGroup = PJN_MetricsCtrl.getMetricCountsByGroup(patientId, carePlanId, true);
        Test.stopTest();

        System.assert(metricCountsByGroup.containsKey(alphaMetricGroupId));
        System.assertEquals(10, metricCountsByGroup.get(alphaMetricGroupId));
    }

    @isTest
    private static void itShouldReturnMetricCountsByGroup() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;

        Test.startTest();
        Map<Id, Integer> metricCountsByGroup = PJN_MetricsCtrl.getMetricCountsByGroup(patientId, carePlanId, false);
        Test.stopTest();

        System.assert(metricCountsByGroup.containsKey(alphaMetricGroupId));
        System.assertEquals(5, metricCountsByGroup.get(alphaMetricGroupId));
    }

    @isTest
    private static void itShouldReturnActiveMetricTypesForGroup() {
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;

        Test.startTest();
        List<PJN_Metric_Type__c> metricTypes = PJN_MetricsCtrl.getMetricTypes(alphaMetricGroupId);
        Test.stopTest();

        System.assertEquals(5, metricTypes.size());
        System.assertEquals('Group 5', metricTypes[3].Name);
    }

    @isTest
    private static void itShouldReturnMetricTypesWithOptions() {
        Id metricTypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE PJN_Type__c='Picklist' LIMIT 1].Id;

        Test.startTest();
        PJN_Metric_Type__c metricType = PJN_MetricsCtrl.getMetricTypeWithOptions(metricTypeId);
        Test.stopTest();

        System.assertEquals('Picklist', metricType.PJN_Type__c);
        System.assertEquals(3, metricType.PJN_Metric_Type_Options__r.size());
        System.assertEquals('Option 1', metricType.PJN_Metric_Type_Options__r[0].Name);
        System.assertEquals('Option 2', metricType.PJN_Metric_Type_Options__r[1].Name);
    }

    @isTest
    private static void itShouldReturnMetricCountsByTypeShowingAll() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;
        Id group1TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 1' LIMIT 1].Id;
        Id group6TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 6' LIMIT 1].Id;

        Test.startTest();
        Map<Id, Integer> metricCountsByType = PJN_MetricsCtrl.getMetricCountsByType(patientId, carePlanId, alphaMetricGroupId, true);
        Test.stopTest();

        System.assert(metricCountsByType.containsKey(group1TypeId));
        System.assertEquals(2, metricCountsByType.get(group1TypeId));
        System.assert(metricCountsByType.containsKey(group6TypeId));
        System.assertEquals(8, metricCountsByType.get(group6TypeId));
    }

    @isTest
    private static void itShouldReturnMetricCountsByType() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;
        Id group1TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 1' LIMIT 1].Id;
        Id group6TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 6' LIMIT 1].Id;

        Test.startTest();
        Map<Id, Integer> metricCountsByType = PJN_MetricsCtrl.getMetricCountsByType(patientId, carePlanId, alphaMetricGroupId, false);
        Test.stopTest();

        System.assert(metricCountsByType.containsKey(group1TypeId));
        System.assertEquals(1, metricCountsByType.get(group1TypeId));
        System.assert(metricCountsByType.containsKey(group6TypeId));
        System.assertEquals(4, metricCountsByType.get(group6TypeId));
    }

    @isTest
    private static void itShouldReturnMetricsShowingAll() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id group6TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 6' LIMIT 1].Id;

        Test.startTest();
        List<PJN_Medical_History__c> metrics = PJN_MetricsCtrl.getMetrics(patientId, carePlanId, group6TypeId, true);
        Test.stopTest();

        System.assertEquals(8, metrics.size());
        System.assertEquals('Option 2', metrics[0].PJN_Value__c);
    }

    @isTest
    private static void itShouldReturnMetrics() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id group6TypeId = [SELECT Id FROM PJN_Metric_Type__c WHERE Name ='Group 6' LIMIT 1].Id;

        Test.startTest();
        List<PJN_Medical_History__c> metrics = PJN_MetricsCtrl.getMetrics(patientId, carePlanId, group6TypeId, false);
        Test.stopTest();

        System.assertEquals(4, metrics.size());
        System.assertEquals('Option 2', metrics[0].PJN_Value__c);
    }

    @isTest
    private static void itShouldReturnGroupSummaryShowingAll() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;

        Test.startTest();
        List<PJN_Medical_History__c> metrics = PJN_MetricsCtrl.getGroupSummary(patientId, carePlanId, alphaMetricGroupId, true);
        Test.stopTest();

        System.assertEquals(2, metrics.size());
        System.assertEquals('42' , metrics[0].PJN_Value__c);
        System.assertEquals('Option 2' , metrics[1].PJN_Value__c);
    }

    @isTest
    private static void itShouldReturnGroupSummary() {
        Id patientId = [SELECT Id FROM Account LIMIT 1].Id;
        Id carePlanId = [SELECT Id FROM Case LIMIT 1].Id;
        Id alphaMetricGroupId = [SELECT Id FROM PJN_Metric_Group__c WHERE Name = 'Alpha' LIMIT 1].Id;

        Test.startTest();
        List<PJN_Medical_History__c> metrics = PJN_MetricsCtrl.getGroupSummary(patientId, carePlanId, alphaMetricGroupId, false);
        Test.stopTest();

        System.assertEquals(2, metrics.size());
        System.assertEquals('42' , metrics[0].PJN_Value__c);
        System.assertEquals('Option 2' , metrics[1].PJN_Value__c);
    }
}