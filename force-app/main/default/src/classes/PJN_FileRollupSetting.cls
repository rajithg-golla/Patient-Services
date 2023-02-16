/**
 * @author Mavens
 * @date Feb 2019
 * @description Accessor class for PJN_File_Rollup_Setting__mdt custom metadata
 * @group Files
 */
public with sharing class PJN_FileRollupSetting {

    @TestVisible
    public static List<PJN_File_Rollup_Setting__mdt> fileSettings {
        get {
            if (fileSettings == null) {
                fileSettings =  [
                    SELECT
                        PJN_sObject_API_Name__c, PJN_Parent_Lookup_Field_API_Name__c
                    FROM
                        PJN_File_Rollup_Setting__mdt
                ];
                if (Test.isRunningTest()) {
                    fileSettings = new PJN_TestFactoryFileRollupSetting().createFileRollupSettingDefaulted();
                }
            }
            return fileSettings;
        }
        private set;
    }

    public static Map<String, PJN_File_Rollup_Setting__mdt> fileSettingsByObjectType {
        get {
            if (fileSettingsByObjectType == null) {
                fileSettingsByObjectType = new Map<String, PJN_File_Rollup_Setting__mdt>();
                for(PJN_File_Rollup_Setting__mdt setting : fileSettings) {
                    fileSettingsByObjectType.put(setting.PJN_sObject_API_Name__c, setting);
                }
            }
            return fileSettingsByObjectType;
        }
        private set;
    }

}