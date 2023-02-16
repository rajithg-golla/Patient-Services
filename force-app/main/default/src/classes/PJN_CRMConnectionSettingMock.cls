@SuppressWarnings('PMD.ExcessiveParameterList')
@isTest(isParallel=true) public with sharing class PJN_CRMConnectionSettingMock implements System.StubProvider {


    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        System.debug('stubbedMethodName: ' + stubbedMethodName);
        System.debug('returnType: ' + returnType);
        System.debug('listOfArgs: ' + listOfArgs);
        if (stubbedMethodName == 'queryBySettingByType') {
            return this.queryBySettingByType((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryBySettingByType(String pjnType) {
        List<PJN_CRM_Connection_Setting__mdt> crmConnectionSettings = new List<PJN_CRM_Connection_Setting__mdt>();
        System.debug('pjnType: ' + pjnType);
        if (pjnType == 'Case Escalation') {
            crmConnectionSettings.add(
                new PJN_CRM_Connection_Setting__mdt(
                    PJN_Active__c = true,
                    PJN_CRM_Connection_Class__c = 'PJN_VeevaCRMSuggestionConnector',
                    PJN_Named_Credential__c = 'PJN_Veeva_CRM',
                    PJN_Trigger_Field__c = 'PJN_Send_to_Veeva_CRM__c'
                )
            );
        } else if (pjnType == 'Sync') {
            crmConnectionSettings.add(
                new PJN_CRM_Connection_Setting__mdt(
                    PJN_Active__c = true,
                    PJN_CRM_Connection_Class__c = 'PJN_VeevaCRMToCaseConnector',
                    PJN_Named_Credential__c = 'PJN_Veeva_CRM',
                    PJN_Case_Sync_Dismissed_Status__c = 'Cancelled',
                    PJN_Case_Sync_Complete_Status__c = 'Closed'
                )
            );
        } else if (pjnType == 'Enrollment') {
            crmConnectionSettings.add(
                new PJN_CRM_Connection_Setting__mdt(
                    PJN_Active__c = true,
                    PJN_CRM_Connection_Class__c = 'PJN_VeevaCRMEnrollmentConnector',
                    PJN_Named_Credential__c = 'PJN_Veeva_CRM',
                    PJN_Trigger_Field__c = 'PJN_Send_to_Veeva_CRM__c'
                )
            );
        }
        return crmConnectionSettings;
    }
}