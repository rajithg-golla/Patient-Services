/**
 * @author      Mavens
 * @group       AccountTypeSettings
 * @description Accessor for Account Type Settings custom metadata
 */
public with sharing class PJN_AccountTypeSettings {

    private static Map<String, SObjectField> typeMap = Schema.getGlobalDescribe()
        .get('PJN_Account_Type_Setting__mdt')
        .getDescribe()
        .fields.getMap();

    public static List<PJN_Account_Type_Setting__mdt> searchTypes(Boolean personSearch) {
        return Database.query(getQueryString('PJN_Include_In_Search__c'));
    }

    public static List<PJN_Account_Type_Setting__mdt> createTypes(Boolean personSearch) {
        return Database.query(getQueryString('PJN_Include_in_Create__c'));
    }

    private static String getQueryString(String filterField) {
        return 'SELECT ' + String.join(new List<String>(typeMap.keySet()), ', ')
            + ' FROM PJN_Account_Type_Setting__mdt'
            + ' WHERE PJN_Is_Person_Record_Type__c = :personSearch'
            + ' AND ' + filterField + ' = true'
            + ' ORDER BY PJN_Account_Search_Order__c';
    }

    public static List<PJN_Account_Type_Setting__mdt> allSettings {
        get {
            if (allSettings == null) {
                List<String> fields = new List<String>(typeMap.keySet());

                String queryString = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ','))
                                    + ' FROM PJN_Account_Type_Setting__mdt';
                allSettings = Database.query(queryString);
                if (Test.isRunningTest()) {
                    //fileSettings = new PJN_TestFactoryFileRollupSetting().createFileRollupSettingDefaulted();
                }
            }
            return allSettings;
        }
        private set;
    }

    public static Map<String, PJN_Account_Type_Setting__mdt> settingsByRecordType {
        get {
            if (settingsByRecordType == null) {
                settingsByRecordType = new Map<String, PJN_Account_Type_Setting__mdt>();
                for(PJN_Account_Type_Setting__mdt setting : allSettings) {
                    if (!settingsByRecordType.containsKey(setting.PJN_Account_Record_Type__c)) {
                        settingsByRecordType.put(setting.PJN_Account_Record_Type__c, setting);
                    }
                }
            }
            return settingsByRecordType;
        }
        private set;
    }

}