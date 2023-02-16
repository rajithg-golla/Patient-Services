/**
 * Query Network Object Settings metadata
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkObjectSettingsQuery {

    /**
     * Query all Network Object Settings metadatas
     * @returns `List<PJN_Network_Object_Setting__mdt>`
     */
    public List<PJN_Network_Object_Setting__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_DCR_Record_Type_Name__c,
                PJN_DCR_Record_Field_Id__c,
                PJN_Parent_Account_Field_Name__c,
                PJN_SObject_Name__c,
                PJN_DCR_Record_Types_Allowed__c,
                PJN_Search_Record_Types_Allowed__c,
                PJN_Sync_Record_Types_Allowed__c,
                PJN_Sync_Delay__c
            FROM
                PJN_Network_Object_Setting__mdt
        ];
    }
}