/**
 * Mock for PJN_NetworkObjectSettingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkObjectSettingsMock implements System.StubProvider {

    private static final String PREFIX = Schema.SObjectType.PJN_Network_Object_Setting__mdt.getKeyPrefix();

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
     * Mock all Network Object Settings metadatas
     * @returns `List<PJN_Network_Object_Setting__mdt>`
     */
    public List<PJN_Network_Object_Setting__mdt> queryAll() {
        List<PJN_Network_Object_Setting__mdt> networkObjectSettings = new List<PJN_Network_Object_Setting__mdt>();

        networkObjectSettings.add(
            new PJN_Network_Object_Setting__mdt(
                Label = 'Account',
                PJN_SObject_Name__c = 'Account',
                PJN_DCR_Record_Type_Name__c = PJN_NetworkConstants.DCR_ACCOUNT,
                PJN_DCR_Record_Field_Id__c = 'PJN_Account__c',
                PJN_DCR_Record_Types_Allowed__c = 'All',
                PJN_Search_Record_Types_Allowed__c = 'PJN_Organization,PJN_Physician,PJN_Staff',
                PJN_Sync_Record_Types_Allowed__c = 'All',
                PJN_Sync_Delay__c = 120,
                id = PREFIX + '000000000001'
            )
        );

        networkObjectSettings.add(
            new PJN_Network_Object_Setting__mdt(
                Label = 'Address',
                PJN_SObject_Name__c = 'PJN_Contact_Information__c',
                PJN_DCR_Record_Type_Name__c = PJN_NetworkConstants.DCR_ADDRESS,
                PJN_DCR_Record_Field_Id__c = 'PJN_Contact_Information__c',
                PJN_Parent_Account_Field_Name__c = 'PJN_Account__c',
                PJN_DCR_Record_Types_Allowed__c = 'All',
                PJN_Sync_Record_Types_Allowed__c = 'All',
                PJN_Sync_Delay__c = 0,
                id = PREFIX + '000000000002'
            )
        );

        networkObjectSettings.add(
            new PJN_Network_Object_Setting__mdt(
                Label = 'License',
                PJN_SObject_Name__c = 'PJN_License__c',
                PJN_DCR_Record_Type_Name__c = PJN_NetworkConstants.DCR_LICENSE,
                PJN_DCR_Record_Field_Id__c = 'PJN_License__c',
                PJN_Parent_Account_Field_Name__c = 'PJN_Account__c',
                PJN_DCR_Record_Types_Allowed__c = 'All',
                PJN_Sync_Record_Types_Allowed__c = 'All',
                PJN_Sync_Delay__c = 0,
                id = PREFIX + '000000000003'
            )
        );

        networkObjectSettings.add(
            new PJN_Network_Object_Setting__mdt(
                Label = 'Affiliation',
                PJN_SObject_Name__c = 'PJN_Affiliation__c',
                PJN_DCR_Record_Type_Name__c = 'PJN_Affiliation',
                PJN_DCR_Record_Field_Id__c = 'PJN_Affiliation__c',
                PJN_Parent_Account_Field_Name__c = 'PJN_Child_Account__c',
                PJN_DCR_Record_Types_Allowed__c = 'none',
                PJN_Sync_Record_Types_Allowed__c = 'All',
                PJN_Sync_Delay__c = 0,
                id = PREFIX + '000000000004'
            )
        );

        return networkObjectSettings;
    }
}