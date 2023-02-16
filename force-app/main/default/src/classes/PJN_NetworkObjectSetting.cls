/**
 * Custom metadata settings needed for DCRs
 * PJN_Network_Object_Setting__mdt, PJN_Network_Field_Mapping__mdt & PJN_Network_Value_Mapping__mdt
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkObjectSetting {

    /**
     * Network Object setting query wrapper
     */
    @TestVisible
    private static PJN_NetworkObjectSettingsQuery networkObjectSettingsQuery = new PJN_NetworkObjectSettingsQuery();

    /**
     * Network Record Type Mapping query wrapper
     */
    @TestVisible
    private static PJN_NetworkRecordTypeMappingsQuery networkRecordTypeMappingsQuery = new PJN_NetworkRecordTypeMappingsQuery();

    /**
     * Network Parent Object Filter query wrapper
     */
    @TestVisible
    private static PJN_NetworkParentObjectFilter networkParentObjectFilterQuery = new PJN_NetworkParentObjectFilter();

    /**
     * Network Field mapping query wrapper
     */
    @TestVisible
    private static PJN_NetworkFieldMappingsQuery networkFieldMappingsQuery = new PJN_NetworkFieldMappingsQuery();

    /**
     * All Network Object setting metadatas by SObject name
     */
    private static Map<String, PJN_Network_Object_Setting__mdt> networkObjectSettingsById {
        get {
            if (networkObjectSettingsById != null && !networkObjectSettingsById.isEmpty()) {
                return networkObjectSettingsById;
            }

            List<PJN_Network_Object_Setting__mdt> networkObjectSettings = NetworkObjectSettingsQuery.queryAll();

            networkObjectSettingsById = new Map<String, PJN_Network_Object_Setting__mdt>();

            for (PJN_Network_Object_Setting__mdt networkObjectSetting : networkObjectSettings) {
                networkObjectSettingsById.put(networkObjectSetting.PJN_SObject_Name__c.toLowerCase(), networkObjectSetting);
            }

            return networkObjectSettingsById;
        } set;
    }

    /**
     * All Record Types metadatas by Network Record Type name
     */
    private static Map<String, Map<String, PJN_Network_Record_Type_Mapping__mdt>> recordTypeMappingsByNetworkRecordTypeByObject {
        get {
            if (recordTypeMappingsByNetworkRecordTypeByObject != null && !recordTypeMappingsByNetworkRecordTypeByObject.isEmpty()) {
                return recordTypeMappingsByNetworkRecordTypeByObject;
            }

            List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings = networkRecordTypeMappingsQuery.queryAll();

            recordTypeMappingsByNetworkRecordTypeByObject = new Map<String, Map<String, PJN_Network_Record_Type_Mapping__mdt>>();

            for (PJN_Network_Record_Type_Mapping__mdt networkRecordTypeMapping : networkRecordTypeMappings) {
                Map<String, PJN_Network_Record_Type_Mapping__mdt> recordTypeMappingsByNetworkRecordType = recordTypeMappingsByNetworkRecordTypeByObject.containsKey(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) ?
                    recordTypeMappingsByNetworkRecordTypeByObject.get(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) :
                    new Map<String, PJN_Network_Record_Type_Mapping__mdt>();

                recordTypeMappingsByNetworkRecordType.put(networkRecordTypeMapping.PJN_Network_Record_Type__c.toLowerCase(), networkRecordTypeMapping);

                recordTypeMappingsByNetworkRecordTypeByObject.put(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase(), recordTypeMappingsByNetworkRecordType);
            }

            return networkRecordTypeMappingsByRecordTypeByObject;
        } set;
    }

    /**
     * All Network Record Types metadatas by SFDC Record Type name
     */
    private static Map<String, Map<String, PJN_Network_Record_Type_Mapping__mdt>> networkRecordTypeMappingsByRecordTypeByObject {
        get {
            if (networkRecordTypeMappingsByRecordTypeByObject != null && !networkRecordTypeMappingsByRecordTypeByObject.isEmpty()) {
                return networkRecordTypeMappingsByRecordTypeByObject;
            }

            List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings = networkRecordTypeMappingsQuery.queryAll();

            networkRecordTypeMappingsByRecordTypeByObject = new Map<String, Map<String, PJN_Network_Record_Type_Mapping__mdt>>();

            for (PJN_Network_Record_Type_Mapping__mdt networkRecordTypeMapping : networkRecordTypeMappings) {
                Map<String, PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappingsByRecordType = networkRecordTypeMappingsByRecordTypeByObject.containsKey(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) ?
                    networkRecordTypeMappingsByRecordTypeByObject.get(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) :
                    new Map<String, PJN_Network_Record_Type_Mapping__mdt>();

                networkRecordTypeMappingsByRecordType.put(networkRecordTypeMapping.PJN_Record_Type_Name__c.toLowerCase(), networkRecordTypeMapping);

                networkRecordTypeMappingsByRecordTypeByObject.put(networkRecordTypeMapping.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase(), networkRecordTypeMappingsByRecordType);
            }

            return networkRecordTypeMappingsByRecordTypeByObject;
        } set;
    }

    /**
     * All Network Field mappings by SObject Record Type Name by SObject name
     */
    private static Map<String, Map<String, List<PJN_Network_Field_Mapping__mdt>>> networkFieldMappingsByRTByObjName {
        get {
            if (networkFieldMappingsByRTByObjName != null && !networkFieldMappingsByRTByObjName.isEmpty()) {
                return networkFieldMappingsByRTByObjName;
            }

            List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = NetworkFieldMappingsQuery.queryAllWithValues();

            networkFieldMappingsByRTByObjName = new Map<String, Map<String, List<PJN_Network_Field_Mapping__mdt>>>();

            for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
                Map<String, List<PJN_Network_Field_Mapping__mdt>> networkFieldMappingsByRT = networkFieldMappingsByRTByObjName.containsKey(networkFieldMapping.PJN_Network_Object__r.PJN_SObject_Name__c.toLowerCase()) ?
                networkFieldMappingsByRTByObjName.get(networkFieldMapping.PJN_Network_Object__r.PJN_SObject_Name__c.toLowerCase()) :
                    new Map<String, List<PJN_Network_Field_Mapping__mdt>>();

                Set<String> currentSObjectRecordTypes = new Set<String>();

                if (networkFieldMapping.PJN_SObject_Record_Type__c.contains(',')) {
                    currentSObjectRecordTypes.addAll(networkFieldMapping.PJN_SObject_Record_Type__c.replaceAll('\\s+','').split(','));
                } else {
                    currentSObjectRecordTypes.add(networkFieldMapping.PJN_SObject_Record_Type__c);
                }

                for (String currentSObjectRecordType : currentSObjectRecordTypes) {
                    List<PJN_Network_Field_Mapping__mdt> currentNetworkFieldMappings = networkFieldMappingsByRT.containsKey(currentSObjectRecordType.toLowerCase()) ?
                    networkFieldMappingsByRT.get(currentSObjectRecordType.toLowerCase()) :
                        new List<PJN_Network_Field_Mapping__mdt>();

                    currentNetworkFieldMappings.add(networkFieldMapping);
                    networkFieldMappingsByRT.put(currentSObjectRecordType.toLowerCase(), currentNetworkFieldMappings);
                }

                networkFieldMappingsByRTByObjName.put(networkFieldMapping.PJN_Network_Object__r.PJN_SObject_Name__c.toLowerCase(), networkFieldMappingsByRT);
            }

            return networkFieldMappingsByRTByObjName;
        }set;
    }

    /**
     * All Network Parent Object FIlter by SObject Record Type Name by SObject name
     */
    private static Map<String, Map<String, List<PJN_Network_Parent_Object_Filter__mdt>>> networkParentFiltersByRTByObjName {
        get {
            if (networkParentFiltersByRTByObjName != null && !networkParentFiltersByRTByObjName.isEmpty()) {
                return networkParentFiltersByRTByObjName;
            }

            List<PJN_Network_Parent_Object_Filter__mdt> networkParentObjectFilters = networkParentObjectFilterQuery.queryAll();

            networkParentFiltersByRTByObjName = new Map<String, Map<String, List<PJN_Network_Parent_Object_Filter__mdt>>>();

            for (PJN_Network_Parent_Object_Filter__mdt networkParentObjectFilter : networkParentObjectFilters) {
                Map<String, List<PJN_Network_Parent_Object_Filter__mdt>> networkParentObjectFiltersByRT = networkParentFiltersByRTByObjName.containsKey(networkParentObjectFilter.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) ?
                    networkParentFiltersByRTByObjName.get(networkParentObjectFilter.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase()) :
                    new Map<String, List<PJN_Network_Parent_Object_Filter__mdt>>();

                Set<String> currentSObjectRecordTypes = new Set<String>();

                if (networkParentObjectFilter.PJN_Object_Record_Type__c.contains(',')) {
                    currentSObjectRecordTypes.addAll(networkParentObjectFilter.PJN_Object_Record_Type__c.replaceAll('\\s+','').split(','));
                } else {
                    currentSObjectRecordTypes.add(networkParentObjectFilter.PJN_Object_Record_Type__c);
                }

                for (String currentSObjectRecordType : currentSObjectRecordTypes) {
                    List<PJN_Network_Parent_Object_Filter__mdt> currentNetworkParentFilters = networkParentObjectFiltersByRT.containsKey(currentSObjectRecordType.toLowerCase()) ?
                        networkParentObjectFiltersByRT.get(currentSObjectRecordType.toLowerCase()) :
                        new List<PJN_Network_Parent_Object_Filter__mdt>();

                        currentNetworkParentFilters.add(networkParentObjectFilter);
                        networkParentObjectFiltersByRT.put(currentSObjectRecordType.toLowerCase(), currentNetworkParentFilters);
                }

                networkParentFiltersByRTByObjName.put(networkParentObjectFilter.PJN_Network_Object_Setting__r.PJN_SObject_Name__c.toLowerCase(), networkParentObjectFiltersByRT);
            }

            return networkParentFiltersByRTByObjName;
        }set;
    }

    /**
     * Get Network Object Settings using SObject name
     * @param sobjectName   SObject name to get Network Object settings for
     * @returns `PJN_Network_Object_Setting__mdt`
     */
    public static PJN_Network_Object_Setting__mdt getSettingByName(String sobjectName) {
        PJN_Network_Object_Setting__mdt setting = networkObjectSettingsById.get(sobjectName.toLowerCase());

        if (setting == null) {
            setting = new PJN_Network_Object_Setting__mdt(
                PJN_Sync_Record_Types_Allowed__c = 'none'
            );
        }

        return setting;
    }

    /**
     * Get All Network Field mappings for any record type using SObject name
     * @param sobjectName   SObject name to get Network Field mappings for
     * @returns `List<PJN_Network_Field_Mapping__mdt>`
     */
    public static List<PJN_Network_Field_Mapping__mdt> getMappingsByName(String sobjectName) {
        Map<String, List<PJN_Network_Field_Mapping__mdt>> networkFieldMappingsByRT = networkFieldMappingsByRTByObjName.containsKey(sobjectName.toLowerCase()) ?
            networkFieldMappingsByRTByObjName.get(sobjectName.toLowerCase()) :
            new Map<String, List<PJN_Network_Field_Mapping__mdt>>();

        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        for (String recordTypeName : networkFieldMappingsByRT.keySet()) {
            networkFieldMappings.addAll(networkFieldMappingsByRT.get(recordTypeName.toLowerCase()));
        }

        return networkFieldMappings;
    }

    /**
     * Get Network Field mappings using SObject name and record type dev name
     * @param sobjectName       SObject name to get Network Field mappings for
     * @param recordTypeName    Record type developer name
     * @returns `List<PJN_Network_Field_Mapping__mdt>`
     */
    public static List<PJN_Network_Field_Mapping__mdt> getMappingsByNameAndRecordType(String sobjectName, String recordTypeName) {
        Map<String, List<PJN_Network_Field_Mapping__mdt>> networkFieldMappingsByRT = networkFieldMappingsByRTByObjName.containsKey(sobjectName.toLowerCase()) ?
            networkFieldMappingsByRTByObjName.get(sobjectName.toLowerCase()) :
            new Map<String, List<PJN_Network_Field_Mapping__mdt>>();

        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = String.isNotBlank(recordTypeName) && networkFieldMappingsByRT.containsKey(recordTypeName.toLowerCase()) ?
            networkFieldMappingsByRT.get(recordTypeName.toLowerCase()) :
            new List<PJN_Network_Field_Mapping__mdt>();

        if (networkFieldMappingsByRT.containsKey('all')) {
            networkFieldMappings.addAll(networkFieldMappingsByRT.get('all'));
        }

        return networkFieldMappings;
    }

    /**
     * Get Network Parent Object filters using SObject name and record type dev name
     * @param sobjectName       SObject name to get Network Parent Filters for
     * @param recordTypeName    Record type developer name
     * @returns `List<PJN_Network_Parent_Object_Filter__mdt>`
     */
    public static List<PJN_Network_Parent_Object_Filter__mdt> getParentFiltersByNameAndRecordType(String sobjectName, String recordTypeName) {
        Map<String, List<PJN_Network_Parent_Object_Filter__mdt>> networkParentFiltersByRT = networkParentFiltersByRTByObjName.containsKey(sobjectName.toLowerCase()) ?
            networkParentFiltersByRTByObjName.get(sobjectName.toLowerCase()) :
            new Map<String, List<PJN_Network_Parent_Object_Filter__mdt>>();

        if (networkParentFiltersByRT.isEmpty()) {
            return null;
        }

        List<PJN_Network_Parent_Object_Filter__mdt> networkParentFilters = String.isNotBlank(recordTypeName) && networkParentFiltersByRT.containsKey(recordTypeName.toLowerCase()) ?
            networkParentFiltersByRT.get(recordTypeName.toLowerCase()) :
            new List<PJN_Network_Parent_Object_Filter__mdt>();

        if (networkParentFiltersByRT.containsKey('all')) {
            networkParentFilters.addAll(networkParentFiltersByRT.get('all'));
        }

        return networkParentFilters;
    }

    public static PJN_Network_Record_Type_Mapping__mdt getNetworkRecordTypeMappingByObjectAndRecordTypeName(String sObjectName, String recordTypeName) {
        Boolean hasSObjectName = networkRecordTypeMappingsByRecordTypeByObject == null
            || networkRecordTypeMappingsByRecordTypeByObject.isEmpty()
            || !networkRecordTypeMappingsByRecordTypeByObject.containsKey(sObjectName.toLowerCase());

        if (hasSObjectName) {
            return null;
        }

        Map<String, PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappingByRecordType = networkRecordTypeMappingsByRecordTypeByObject.get(sObjectName.toLowerCase());

        if (networkRecordTypeMappingByRecordType == null || networkRecordTypeMappingByRecordType.isEmpty() || !networkRecordTypeMappingByRecordType.containsKey(recordTypeName.toLowerCase())) {
            return null;
        }

        return networkRecordTypeMappingByRecordType.get(recordTypeName.toLowerCase());
    }

    public static PJN_Network_Record_Type_Mapping__mdt getRecordTypeMappingByObjectAndNetworkRecordTypeName(String sObjectName, String networkRecordTypeName) {
        Boolean hasSObjectName = recordTypeMappingsByNetworkRecordTypeByObject == null
            || recordTypeMappingsByNetworkRecordTypeByObject.isEmpty()
            || !recordTypeMappingsByNetworkRecordTypeByObject.containsKey(sObjectName.toLowerCase());

        if (hasSObjectName) {
            return null;
        }

        Map<String, PJN_Network_Record_Type_Mapping__mdt> recordTypeMappingByNetworkRecordType = recordTypeMappingsByNetworkRecordTypeByObject.get(sObjectName.toLowerCase());

        if (recordTypeMappingByNetworkRecordType == null || recordTypeMappingByNetworkRecordType.isEmpty() || !recordTypeMappingByNetworkRecordType.containsKey(networkRecordTypeName.toLowerCase())) {
            return null;
        }

        return recordTypeMappingByNetworkRecordType.get(networkRecordTypeName.toLowerCase());
    }

    public static List<PJN_Network_Record_Type_Mapping__mdt> getNetworkRecordTypeMappingsByObject(String sObjectName) {
        Boolean hasSObjectName = networkRecordTypeMappingsByRecordTypeByObject == null
            || networkRecordTypeMappingsByRecordTypeByObject.isEmpty()
            || !networkRecordTypeMappingsByRecordTypeByObject.containsKey(sObjectName.toLowerCase());

        if (hasSObjectName) {
            return null;
        }

        Map<String, PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappingByRecordType = networkRecordTypeMappingsByRecordTypeByObject.get(sObjectName.toLowerCase());

        if (networkRecordTypeMappingByRecordType == null || networkRecordTypeMappingByRecordType.isEmpty()) {
            return null;
        }

        return networkRecordTypeMappingByRecordType.values();
    }
}