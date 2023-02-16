/**
 * @author      Mavens
 * @group       MDM
 * @description Mock for MVN_MDMObjectSettingQuery
 */
@IsTest
public with sharing class MVN_MDMObjectSettingMock implements System.StubProvider {

    @TestVisible
    private static final String PREFIX = Schema.SObjectType.MVN_MDM_Object_Setting__mdt.getKeyPrefix();

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryAll') {
            return this.queryAll();
        } else {
            return null;
        }
    }

    /**
     * Initialize all the MDM Object Setting metadatas when query all
     * @return  `List<MVN_MDM_Object_Setting__mdt>`
     */
    public List<MVN_MDM_Object_Setting__mdt> queryAll() {
        List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = new List<MVN_MDM_Object_Setting__mdt>();

        mdmObjectSettings.add(
            new MVN_MDM_Object_Setting__mdt(
                MVN_MDM_Connection__c = MVN_MDMConnectionMock.PREFIX + '000000000001',
                Label = 'MyRare:Account',
                DeveloperName = 'MVN_MyRare_Account',
                MasterLabel = 'MVN_MyRare_Account',
                MVN_SObject_API_Name__c = 'Account',
                MVN_MDM_Object_Name__c = 'patient',
                MVN_Is_Active__c = true,
                id = PREFIX + '000000000001'
            )
        );

        mdmObjectSettings.add(
            new MVN_MDM_Object_Setting__mdt(
                MVN_MDM_Connection__c = MVN_MDMConnectionMock.PREFIX + '000000000001',
                Label = 'MyRare:PAP',
                DeveloperName = 'MVN_MyRare_PAP',
                MasterLabel = 'MVN_MyRare_PAP',
                MVN_SObject_API_Name__c = 'PJN_Assistance_Program__c',
                MVN_MDM_Object_Name__c = 'income',
                MVN_Is_Active__c = true,
                id = PREFIX + '000000000002'
            )
        );

        mdmObjectSettings.add(
            new MVN_MDM_Object_Setting__mdt(
                MVN_MDM_Connection__c = MVN_MDMConnectionMock.PREFIX + '000000000001',
                Label = 'MyRare:Copay',
                DeveloperName = 'MVN_MyRare_Copay',
                MasterLabel = 'MVN_MyRare_Copay',
                MVN_SObject_API_Name__c = 'PJN_Assistance_Program__c',
                MVN_MDM_Object_Name__c = 'insurance',
                MVN_Is_Active__c = true,
                id = PREFIX + '000000000003'
            )
        );

        mdmObjectSettings.add(
            new MVN_MDM_Object_Setting__mdt(
                MVN_MDM_Connection__c = MVN_MDMConnectionMock.PREFIX + '000000000001',
                Label = 'MyRare:Consent',
                DeveloperName = 'MVN_MyRare_Consent',
                MasterLabel = 'MVN_MyRare_Consent',
                MVN_SObject_API_Name__c = 'PJN_Contact_Point_Type_Consent__c',
                MVN_MDM_Object_Name__c = 'consents',
                MVN_Is_Active__c = true,
                id = PREFIX + '000000000004'
            )
        );

        return mdmObjectSettings;
    }
}