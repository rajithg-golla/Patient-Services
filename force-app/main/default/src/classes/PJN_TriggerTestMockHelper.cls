@isTest
public class PJN_TriggerTestMockHelper {

    public static void mock(SObjectType objectType) {
        String objectName = objectType.getDescribe().getName();
        switch on (objectName) {
            when 'PJN_Coverage_Investigation__c' {
                handleCoverageInvestigation();
            }
        }
    }

    private static void handleCoverageInvestigation() {
        List<PJN_Trigger_Handler_Setting__mdt> settings = new List<PJN_Trigger_Handler_Setting__mdt>{
            new PJN_Trigger_Handler_Setting__mdt(
                DeveloperName='PJN_Before_Update_Active_Investigation',
                PJN_Class__c='PJN_ActiveCoverageInvestigationHdlr',
                PJN_Event__c='BEFORE_UPDATE'
            ),
            new PJN_Trigger_Handler_Setting__mdt(
                DeveloperName='PJN_Before_Insert_Active_Investigation',
                PJN_Class__c='PJN_ActiveCoverageInvestigationHdlr',
                PJN_Event__c='BEFORE_INSERT'
            ),
            new PJN_Trigger_Handler_Setting__mdt(
                DeveloperName='PJN_After_Insert_Active_Investigation',
                PJN_Class__c='PJN_ActiveCoverageInvestigationHdlr',
                PJN_Event__c='AFTER_INSERT'
            ),
            new PJN_Trigger_Handler_Setting__mdt(
                DeveloperName='PJN_After_Update_Active_Investigation',
                PJN_Class__c='PJN_ActiveCoverageInvestigationHdlr',
                PJN_Event__c='AFTER_UPDATE'
            )
        };

        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            PJN_Coverage_Investigation__c.SObjectType,
            settings
        );
    }
}