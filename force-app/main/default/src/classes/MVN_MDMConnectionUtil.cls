/**
 * @author      Mavens
 * @group       MDM
 * @description Class to retrieve MDM settings for a connection
 */
public without sharing class MVN_MDMConnectionUtil {

    /**
     * MDM Connection Query wrapper
     */
    @TestVisible
    private static MVN_MDMConnectionQuery mdmConnectionQuery = new MVN_MDMConnectionQuery();

    /**
     * MDM Object Setting Query wrapper
     */
    @TestVisible
    private static MVN_MDMObjectSettingQuery mdmObjectSettingQuery = new MVN_MDMObjectSettingQuery();

    /**
     * MDM Field Mapping Query wrapper
     */
    @TestVisible
    private static MVN_MDMFieldMappingQuery mdmFieldMappingQuery = new MVN_MDMFieldMappingQuery();

    /**
     * Get Map of MDM Connection metadata by MDM Connection Developer Name
     */
    private static Map<String, MVN_MDM_Connection__mdt> mdmConnectionByName {
        get {
            if (mdmConnectionByName != null && !mdmConnectionByName.isEmpty()) {
                return mdmConnectionByName;
            }

            List<MVN_MDM_Connection__mdt> mdmConnections = mdmConnectionQuery.queryAll();

            mdmConnectionByName = new Map<String, MVN_MDM_Connection__mdt>();

            for (MVN_MDM_Connection__mdt mdmConnection : mdmConnections) {
                mdmConnectionByName.put(mdmConnection.DeveloperName.toLowerCase(), mdmConnection);
            }

            return mdmConnectionByName;
        } set;
    }

    /**
     * Get Map of MDM Object Setting metadatas by MDM Connection Id
     */
    private static Map<String, List<MVN_MDM_Object_Setting__mdt>> mdmObjectSettingsByConnection {
        get {
            if (mdmObjectSettingsByConnection != null && !mdmObjectSettingsByConnection.isEmpty()) {
                return mdmObjectSettingsByConnection;
            }

            List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = mdmObjectSettingQuery.queryAll();

            mdmObjectSettingsByConnection = new Map<String, List<MVN_MDM_Object_Setting__mdt>>();

            for (MVN_MDM_Object_Setting__mdt mdmObjectSetting : mdmObjectSettings) {
                List<MVN_MDM_Object_Setting__mdt> currentMDMObjectSettings = mdmObjectSettingsByConnection.containsKey(mdmObjectSetting.MVN_MDM_Connection__c) ?
                    mdmObjectSettingsByConnection.get(mdmObjectSetting.MVN_MDM_Connection__c) :
                    new List<MVN_MDM_Object_Setting__mdt>();
                currentMDMObjectSettings.add(mdmObjectSetting);
                mdmObjectSettingsByConnection.put(mdmObjectSetting.MVN_MDM_Connection__c, currentMDMObjectSettings);
            }

            return mdmObjectSettingsByConnection;
        } set;
    }

    /**
     * Get Map of MDM Field and Value Mapping metadatas by MDM Object Setting Id
     */
    private static Map<String, List<MVN_MDM_Field_Mapping__mdt>> mdmFieldMappingsBySetting {
        get {
            if (mdmFieldMappingsBySetting != null && !mdmFieldMappingsBySetting.isEmpty()) {
                return mdmFieldMappingsBySetting;
            }

            List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = mdmFieldMappingQuery.queryAll();

            mdmFieldMappingsBySetting = new Map<String, List<MVN_MDM_Field_Mapping__mdt>>();

            for (MVN_MDM_Field_Mapping__mdt mdmFieldMapping : mdmFieldMappings) {
                List<MVN_MDM_Field_Mapping__mdt> currentMDMFieldMappings = mdmFieldMappingsBySetting.containsKey(mdmFieldMapping.MVN_MDM_Object_Setting__c) ?
                    mdmFieldMappingsBySetting.get(mdmFieldMapping.MVN_MDM_Object_Setting__c) :
                    new List<MVN_MDM_Field_Mapping__mdt>();
                currentMDMFieldMappings.add(mdmFieldMapping);
                mdmFieldMappingsBySetting.put(mdmFieldMapping.MVN_MDM_Object_Setting__c, currentMDMFieldMappings);
            }

            return mdmFieldMappingsBySetting;
        } set;
    }

    /**
     * Get MDM Connection metadata using MDM Connection Deverloper Name
     * @param connection    MDM Connection Developer Name
     * @return  `MVN_MDM_Connection__mdt`
     */
    public static MVN_MDM_Connection__mdt getConnectionByName(String connection) {
        return mdmConnectionByName.get(connection.toLowerCase());
    }

    /**
     * Get MDM Object Setting metadatas using MDM Connection Id
     * @param connectionId  MDM Connection Id
     * @return  `List<MVN_MDM_Object_Setting__mdt>`
     */
    public static List<MVN_MDM_Object_Setting__mdt> getObjectSettingsByConnection(Id connectionId) {
        return mdmObjectSettingsByConnection.get(connectionId);
    }

    /**
     * Get MDM Object Settings by MDM Connection Id and SFDC Object API Name
     * @param connectionId  MDM Connection Id
     * @param objectName    SFDC Object API Name
     * @return  `List<MVN_MDM_Object_Setting__mdt>`
     */
    public static List<MVN_MDM_Object_Setting__mdt> getObjectSettingsByConnectionAndSFDCObject(Id connectionId, String objectName) {
        List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = new List<MVN_MDM_Object_Setting__mdt>();
        for (MVN_MDM_Object_Setting__mdt mdmObjectSetting : mdmObjectSettingsByConnection.get(connectionId)) {
            if (mdmObjectSetting.MVN_SObject_API_Name__c.toLowerCase() == objectName.toLowerCase()) {
                mdmObjectSettings.add(mdmObjectSetting);
            }
        }
        return mdmObjectSettings;
    }

    /**
     * Get MDM Object Settings using MDM Connection Id and MDM Object API Name
     * @param connectionId  MDM Connection Id
     * @param mdmObjectName MDM Object API Name
     * @return  `List<MVN_MDM_Object_Setting__mdt>`
     */
    public static List<MVN_MDM_Object_Setting__mdt> getObjectSettingsByConnectionAndMDMObject(Id connectionId, String mdmObjectName) {
        List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = new List<MVN_MDM_Object_Setting__mdt>();
        if (connectionId == null || String.isBlank(mdmObjectName)) {
            return mdmObjectSettings;
        }
        List<MVN_MDM_Object_Setting__mdt> currentMDMObjectSettings = mdmObjectSettingsByConnection.get(connectionId);
        if (currentMDMObjectSettings == null) {
            return mdmObjectSettings;
        }
        for (MVN_MDM_Object_Setting__mdt mdmObjectSetting : currentMDMObjectSettings) {
            if (mdmObjectSetting.MVN_MDM_Object_Name__c.toLowerCase() == mdmObjectName.toLowerCase()) {
                mdmObjectSettings.add(mdmObjectSetting);
            }
        }
        return mdmObjectSettings;
    }

    /**
     * Get MDM Inbound Lookup field mappings by MDM Object Setting metadata Id
     * @param settingId MDM Object Setting metadata Id
     * @return  `List<MVN_MDM_Field_Mapping__mdt>`
     */
    public static List<MVN_MDM_Field_Mapping__mdt> getInboundLookupFieldMappingsBySetting(Id settingId) {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();
        for (MVN_MDM_Field_Mapping__mdt mdmFieldMapping : mdmFieldMappingsBySetting.get(settingId)) {
            if (mdmFieldMapping.MVN_Inbound__c && mdmFieldMapping.MVN_Is_Lookup_Field__c) {
                mdmFieldMappings.add(mdmFieldMapping);
            }
        }
        return mdmFieldMappings;
    }

    /**
     * Get MDM Inbound field mappings by MDM Object Setting metadata Id
     * @param settingId MDM Object Setting metadata Id
     * @return  `List<MVN_MDM_Field_Mapping__mdt>`
    */
    public static List<MVN_MDM_Field_Mapping__mdt> getInboundFieldMappingsBySetting(Id settingId) {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();
        if (settingId == null || mdmFieldMappingsBySetting == null) {
            return mdmFieldMappings;
        }
        List<MVN_MDM_Field_Mapping__mdt> allMDMFieldMappings = mdmFieldMappingsBySetting.get(settingId);
        if (allMDMFieldMappings == null) {
            return mdmFieldMappings;
        }
        for (MVN_MDM_Field_Mapping__mdt mdmFieldMapping : allMDMFieldMappings) {
            if (mdmFieldMapping.MVN_Inbound__c) {
                mdmFieldMappings.add(mdmFieldMapping);
            }
        }
        return mdmFieldMappings;
    }

    /**
     * Get Value in the correct display type
     * @param sObjectName   SFDC Object API Name
     * @param fieldName     SFDC Field API Name
     * @param value         Value to be converted
     * @return  `Object`
     */
    public static Object getValue(String sObjectName, String fieldName, Object value) {
        if (value != null && Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().containsKey(fieldName)) {
            Schema.DisplayType displayType = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
            switch on (String) displayType.name() {
                when 'BOOLEAN' {
                    return Boolean.valueOf(value);
                }
                when 'ADDRESS' {
                    return String.valueOf(value);
                }
                when 'COMBOBOX' {
                    return String.valueOf(value);
                }
                when 'CURRENCY' {
                    return Decimal.valueOf(String.valueOf(value));
                }
                when 'DOUBLE' {
                    return Decimal.valueOf(String.valueOf(value));
                }
                when 'PERCENT' {
                    return Decimal.valueOf(String.valueOf(value));
                }
                when 'DATE' {
                    Date myDate;
                    try {
                        myDate = Date.parse((String) value);
                    } catch (Exception exc) {
                        myDate = Date.valueOf((String) value);
                    }
                    return myDate;
                }
                when 'DATETIME' {
                    return DateTime.valueOf(value);
                }
                when 'DATACATEGORYGROUPREFERENCE' {
                    return String.valueOf(value);
                }
                when 'EMAIL' {
                    return String.valueOf(value);
                }
                when 'ENCRYPTEDSTRING' {
                    return String.valueOf(value);
                }
                when 'LONG' {
                    return value;
                }
                when 'PHONE' {
                    return String.valueOf(value);
                }
                when 'PICKLIST' {
                    return String.valueOf(value);
                }
                when 'REFERENCE' {
                    return String.valueOf(value);
                }
                when 'STRING' {
                    return String.valueOf(value);
                }
                when 'TEXTAREA' {
                    return String.valueOf(value);
                }
                when 'URL' {
                    return String.valueOf(value);
                }
            }
        }
        return null;
    }
}