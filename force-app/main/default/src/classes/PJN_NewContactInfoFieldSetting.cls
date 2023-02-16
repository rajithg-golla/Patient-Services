/**
 * @author Mavens
 * @date Feb 2019
 * @description Accessor class for PJN_New_Contact_Info_Fields_Setting__mdt custom metadata
 * @group AccountSearch
 */
public with sharing class PJN_NewContactInfoFieldSetting {

    public static List<PJN_New_Contact_Info_Fields_Setting__mdt> allSettings {
        get {
            if (allSettings == null) {
                Map<String, Schema.SObjectField> fieldMapping = 
                    PJN_New_Contact_Info_Fields_Setting__mdt.sObjectType.getDescribe().Fields.getMap();
                List<String> fields = new List<String>(fieldMapping.keySet());

                String queryString = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ','))
                                    + ' FROM PJN_New_Contact_Info_Fields_Setting__mdt'
                                    + ' ORDER BY PJN_Order__c';
                allSettings = Database.query(queryString);
                if (Test.isRunningTest()) {
                    //fileSettings = new PJN_TestFactoryFileRollupSetting().createFileRollupSettingDefaulted();
                }
            }
            return allSettings;
        }
        private set;
    }

    public static Map<String, List<PJN_New_Contact_Info_Fields_Setting__mdt>> settingsByRecordType {
        get {
            if (settingsByRecordType == null) {
                settingsByRecordType = new Map<String, List<PJN_New_Contact_Info_Fields_Setting__mdt>>();
                for(PJN_New_Contact_Info_Fields_Setting__mdt setting : allSettings) {
                    if (!settingsByRecordType.containsKey(setting.PJN_Record_Type__c)) {
                        settingsByRecordType.put(setting.PJN_Record_Type__c, new List<PJN_New_Contact_Info_Fields_Setting__mdt>());
                    }
                    settingsByRecordType.get(setting.PJN_Record_Type__c).add(setting);
                }
            }
            return settingsByRecordType;
        }
        private set;
    }

    public static Map<Id, List<PJN_New_Contact_Info_Fields_Setting__mdt>> settingsByRecordTypeId {
        get {
            if (settingsByRecordTypeId == null) {
                Map<String, Schema.RecordTypeInfo> recordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
                settingsByRecordTypeId = new Map<Id, List<PJN_New_Contact_Info_Fields_Setting__mdt>>();
                for(PJN_New_Contact_Info_Fields_Setting__mdt setting : allSettings) {
                    Id recordTypeId = recordTypeMap.get(setting.PJN_Record_Type__c).getRecordTypeId();
                    if (!settingsByRecordTypeId.containsKey(recordTypeId)) {
                        settingsByRecordTypeId.put(recordTypeId, new List<PJN_New_Contact_Info_Fields_Setting__mdt>());
                    }
                    settingsByRecordTypeId.get(recordTypeId).add(setting);
                }
            }
            return settingsByRecordTypeId;
        }
        private set;
    }

}