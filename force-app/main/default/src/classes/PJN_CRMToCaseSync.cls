/**
 * Network Case Sync controller
 * @author  Mavens
 */
public with sharing class PJN_CRMToCaseSync {

    @testVisible private static PJN_CRMConnectionSettingQuery crmConnectionSettingQuery = new PJN_CRMConnectionSettingQuery();

    @AuraEnabled
    public static Boolean syncEscalatedCases(Id recordId) {

        Boolean result = true;

        for (PJN_CRM_Connection_Setting__mdt connectionSetting : crmConnectionSettingQuery.queryBySettingByType('Sync')) {
            Type crmToCaseConnector = Type.forName(connectionSetting.PJN_CRM_Connection_Class__c);
            PJN_ICRMToCaseConnector crmConnectorInstance = (PJN_ICRMToCaseConnector) crmToCaseConnector.newInstance();
            if (!crmConnectorInstance.syncEscalatedCases(connectionSetting, recordId)) {
                result = false;
            }
        }

        return result;
    }
}