/**
 * @author      Mavens
 * @date        March 2019
 * @description Class to provide factory methods to create test custom metadata for GlocalSettings
 * @group       TestFactory
 */
@isTest(isParallel=true) public class PJN_TestFactoryGlobalSetting {
    public static void setMock() {
        setMock(null);
    }

    public static void setMock(Map<String, Object> fieldValues) {
        PJN_Global_Setting__mdt setting = new PJN_Global_Setting__mdt(
            MasterLabel = 'Global Setting',
            DeveloperName = 'PJN_Global_Setting',
            PJN_Account_Search_Handler_Classes__c = 'PJN_AccountSearchHdlr',
            PJN_Account_Search_Max_Results__c = 200,
            PJN_Enable_Event_Automation__c = true,
            PJN_Create_DCR__c = true,
            PJN_Network_API_Version__c = PJN_NetworkConstants.NETWORK_API_VERSION,
            PJN_Network_Named_Credential__c = PJN_NetworkConstants.NETWORK_NAMED_CREDENTIAL,
            PJN_Network_System__c = PJN_NetworkConstants.NETWORK_SYSTEM,
            PJN_Transaction_Log_Level__c = 'All',
            PJN_Veeva_Network__c = true,
            PJN_Contact_Info_Address_Record_Types__c = 'PJN_Address',
            PJN_Contact_Info_Email_Record_Types__c = 'PJN_Email',
            PJN_Contact_Info_Phone_Record_Types__c = 'PJN_Phone',
            PJN_Contact_Info_Fax_Record_Types__c = 'PJN_Fax'
        );

        if(fieldValues != null) {
            for(String field : fieldValues.keySet()) {
                setting.put(field, fieldValues.get(field));
            }
        }

        PJN_Utilities.globalSettingMock = setting;
    }
}