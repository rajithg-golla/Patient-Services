/**
 * @author Mavens
 * @description Unit tests for PJN_CRMConnectionSettingQuery
 */
@isTest(isParallel=true) public with sharing class PJN_CRMConnectionSettingQueryTest {
    @isTest private static void queryBySettingByTypeTest() {
        PJN_CRMConnectionSettingQuery crmConnectionSettingQuery = new PJN_CRMConnectionSettingQuery();

        Test.startTest();
            List<PJN_CRM_Connection_Setting__mdt> crmConnectionSettings = crmConnectionSettingQuery.queryBySettingByType('Sync');
        Test.stopTest();

        List<PJN_CRM_Connection_Setting__mdt> verifyCrmConnectionSettings = [SELECT Id FROM PJN_CRM_Connection_Setting__mdt WHERE PJN_Type__c = 'Sync' AND PJN_Active__c = TRUE];

        System.assertEquals(verifyCrmConnectionSettings.size(), crmConnectionSettings.size(), 'Query results do not match results from standard query.');
    }
}