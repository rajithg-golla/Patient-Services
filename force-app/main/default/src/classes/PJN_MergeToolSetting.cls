/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query PJN_Merge_Tool_Setting__mdt custom metadata
 * @group PatientMerge
 */
public with sharing class PJN_MergeToolSetting {

    /**
     * getAllSettings Query all records for Merge Tool Settings
     * @returns   List<PJN_Merge_Tool_Setting__mdt>
     */
    public List<PJN_Merge_Tool_Setting__mdt> getAllSettings() {
        Map<String, Schema.SObjectField> setting =
            PJN_Merge_Tool_Setting__mdt.sObjectType.getDescribe().Fields.getMap();
        List<String> fields = new List<String>(setting.keySet());
        String queryString = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ','))
                            + ' FROM PJN_Merge_Tool_Setting__mdt'
                            + ' ORDER BY PJN_Order__c';
        return Database.query(queryString);
    }

    /**
     * getAllSettingsByObjectName Query all records for Merge Tool Setting and return a map of them by object name
     * @returns   Map<String, PJN_Merge_Tool_Setting__mdt>
     */
    public Map<String, PJN_Merge_Tool_Setting__mdt> getAllSettingsByObjectName() {
        Map<String, PJN_Merge_Tool_Setting__mdt> allSettingsByObjectName = new Map<String, PJN_Merge_Tool_Setting__mdt>();
        for (PJN_Merge_Tool_Setting__mdt setting : getAllSettings()) {
            allSettingsByObjectName.put(setting.PJN_Child_SObject_API_Name__c, setting);
        }
        return allSettingsByObjectName;
    }
}