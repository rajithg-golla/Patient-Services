/**
 * @author      Mavens
 * @group       MyRare.com
 * @description Wrapper for MyRare Objects
 */
public with sharing class MVN_MyRareObject {

    /**
     * Current SObject API Name
     */
    private String sObjectName;

    /**
     * Current SObject Record Type Developer Name
     */
    private String recordTypeDevName;

    /**
     * MDM Connection metadata Developer Name for MyRare.com
     */
    private static final String MYRARE_CONNECTION = 'MVN_MyRare';

    /**
     * MyRare Object constructor using Object API Name
     * @param sObjectName   SFDC Object API Name
     */
    public MVN_MyRareObject(String sObjectName) {
        this.sObjectName = sObjectName;
        this.recordTypeDevName = null;
    }

    /**
     * MyRare Object constructor using Object API Name and Record Type Developer Name
     * @param sObjectName       SFDC Object API Name
     * @param recordTypeDevName Record Type Developer Name
     */
    public MVN_MyRareObject(String sObjectName, String recordTypeDevName) {
        this.sObjectName = sObjectName;
        this.recordTypeDevName = recordTypeDevName;
    }

    /**
     * Get List of SFDC Objects using MyRare Request mapped
     * Converts every mdm object into a sfdc object using MDM metadata mappings
     * @param myRareRequest     MyRare.com Request
     * @param requestObjects    Object property in the JSON request
     * @return  `List<SObject>`
     */
    public List<SObject> getMyRareObjects(Map<String, Object> myRareRequest, String requestObjects) {
       
        List<SObject> sobjects = new List<SObject>();
        if (!myRareRequest.containsKey(requestObjects.toLowerCase()) || myRareRequest.get(requestObjects.toLowerCase()) == null) {
            return sobjects;
        }
       
        List<Object> sObjectRequests = (List<Object>) myRareRequest.get(requestObjects.toLowerCase());
        system.debug('sObjectRequests' + sObjectRequests);
        MVN_MDM_Connection__mdt mdmConnection = MVN_MDMConnectionUtil.getConnectionByName(MYRARE_CONNECTION);
        List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = MVN_MDMConnectionUtil.getObjectSettingsByConnectionAndMDMObject(mdmConnection.Id, requestObjects.toLowerCase());
        if (mdmObjectSettings.isEmpty()) {
            return sobjects;
        }
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = MVN_MDMConnectionUtil.getInboundFieldMappingsBySetting(mdmObjectSettings[0].Id);
        if (mdmFieldMappings == null || mdmFieldMappings.isEmpty()) {
            return sobjects;
        }
        List<MVN_MDM_Field_Mapping__mdt> mdmLookupFieldMappings = MVN_MDMConnectionUtil.getInboundLookupFieldMappingsBySetting(mdmObjectSettings[0].Id);
        Map<String, Map<String, Id>> idsByNameByLookupField = new Map<String, Map<String, Id>>();
        if (!mdmLookupFieldMappings.isEmpty()) {
            idsByNameByLookupField = getIdsByNameByLookupField(sObjectRequests, mdmLookupFieldMappings);
        }
        for (Object sObjectRequestObj : sObjectRequests) {
            Map<String, Object> sObjectRequest = (Map<String, Object>) sObjectRequestObj;
            SObject thisObject = Schema.getGlobalDescribe().get(sObjectName).newSObject();
            if (String.isNotBlank(recordTypeDevName)) {
                thisObject.put('RecordTypeId', Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId());
            }
            for (MVN_MDM_Field_Mapping__mdt mdmFieldMapping : mdmFieldMappings) {
                Object value = getValueMapped(sObjectRequest.get(mdmFieldMapping.MVN_MDM_Field__c.toLowerCase()), mdmFieldMapping);
                if (!idsByNameByLookupField.isEmpty() && mdmFieldMapping.MVN_Is_Lookup_Field__c && idsByNameByLookupField.containsKey(mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase())) {
                    Map<String, Id> idsByName = idsByNameByLookupField.get(mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase());
                    value = idsByName.get(String.valueOf(value));
                }
                thisObject.put(
                    mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase(),
                    MVN_MDMConnectionUtil.getValue(
                        sObjectName,
                        mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase(),
                        value
                    )
                );
            }
            sobjects.add(thisObject);
        }
       
        return sobjects;
        
    }

    /**
     * Gets the Lookup Id using the filter field value as key by filter field name
     * Ex: MyCustomField__c => {TestFieldValue => 01241092013xASFG}
     * @param sObjectRequests           List of MDM Object records
     * @param mdmLookupFieldMappings    MDM Lookup Field Mapping metadatas
     * @return  `Map<String, Map<String, Id>>`
     */
    private Map<String, Map<String, Id>> getIdsByNameByLookupField(List<Object> sObjectRequests, List<MVN_MDM_Field_Mapping__mdt> mdmLookupFieldMappings) {
        Map<String, Map<String, Id>> idsByNameByLookupField = new Map<String, Map<String, Id>>();
        Map<String, MVN_MDM_Field_Mapping__mdt> mdmFieldMappingByLookupField = new Map<String, MVN_MDM_Field_Mapping__mdt>();
        for (MVN_MDM_Field_Mapping__mdt mdmLookupFieldMapping : mdmLookupFieldMappings) {
            Map<String, Id> idsByName = new Map<String, Id>();
            for (Object sObjectRequestObj : sObjectRequests) {
                Map<String, Object> sObjectRequest = (Map<String, Object>) sObjectRequestObj;
                String currentValue = String.valueOf(getValueMapped(sObjectRequest.get(mdmLookupFieldMapping.MVN_MDM_Field__c), mdmLookupFieldMapping));
                idsByName.put(currentValue, null);
            }
            idsByNameByLookupField.put(mdmLookupFieldMapping.MVN_SFDC_Field__c.toLowerCase(), idsByName);
            mdmFieldMappingByLookupField.put(mdmLookupFieldMapping.MVN_SFDC_Field__c.toLowerCase(), mdmLookupFieldMapping);
        }
        for (String lookupField : mdmFieldMappingByLookupField.keySet()) {
            MVN_MDM_Field_Mapping__mdt mdmFieldMapping = mdmFieldMappingByLookupField.get(lookupField);
            Map<String, Id> idsByName = idsByNameByLookupField.get(lookupField);
            Set<String> recordNames = idsByName.keySet();
            String query = String.format(
                'SELECT Id, {1} FROM {0} WHERE {1} IN :recordNames',
                new List<String> {
                    mdmFieldMapping.MVN_Lookup_sObject__c,
                    mdmFieldMapping.MVN_Lookup_Field_Filter__c
                }
            );
            for (SObject record : Database.query(query)) {
                idsByName.put(String.valueOf(record.get(mdmFieldMapping.MVN_Lookup_Field_Filter__c)), String.valueOf(record.get('Id')));
            }
            idsByNameByLookupField.put(lookupField, idsByName);
        }
        return idsByNameByLookupField;
    }

    /**
     * Get SFDC Object using MyRare Request mapped
     * Converts mdm object into a sfdc object using MDM metadata mappings
     * @param myRareRequest MyRare.com Request
     * @param requestObject Object property in the JSON request
     * @return  `SObject`
     */
    public SObject getMyRareObject(Map<String, Object> myRareRequest, String requestObject) {
      
        if (!myRareRequest.containsKey(requestObject)) {
            return null;
        }
        Map<String, Object> sObjectRequest = (Map<String, Object>) myRareRequest.get(requestObject);
       
        if(sObjectRequest == null){
            return null;
        }
        MVN_MDM_Connection__mdt mdmConnection = MVN_MDMConnectionUtil.getConnectionByName(MYRARE_CONNECTION);
        List<MVN_MDM_Object_Setting__mdt> mdmObjectSettings = MVN_MDMConnectionUtil.getObjectSettingsByConnectionAndMDMObject(mdmConnection.Id, requestObject);
        if (mdmObjectSettings.isEmpty()) {
            return null;
        }
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = MVN_MDMConnectionUtil.getInboundFieldMappingsBySetting(mdmObjectSettings[0].Id);
        if (mdmFieldMappings == null || mdmFieldMappings.isEmpty()) {
            return null;
        }
        List<MVN_MDM_Field_Mapping__mdt> mdmLookupFieldMappings = MVN_MDMConnectionUtil.getInboundLookupFieldMappingsBySetting(mdmObjectSettings[0].Id);
        Map<String, Map<String, Id>> idsByNameByLookupField = new Map<String, Map<String, Id>>();
        if (!mdmLookupFieldMappings.isEmpty()) {
            idsByNameByLookupField = getIdsByNameByLookupField(new List<Object> {sObjectRequest}, mdmLookupFieldMappings);
        }
        SObject thisObject = Schema.getGlobalDescribe().get(sObjectName).newSObject();
        if (String.isNotBlank(recordTypeDevName)) {
            thisObject.put('RecordTypeId', Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId());
        }
        Boolean hasAnyValue = false;
        for (MVN_MDM_Field_Mapping__mdt mdmFieldMapping : mdmFieldMappings) {
            system.debug('mdmFieldMapping.MVN_MDM_Field__c.toLowerCase()' + mdmFieldMapping.MVN_MDM_Field__c.toLowerCase());
            Object value = getValueMapped(sObjectRequest.get(mdmFieldMapping.MVN_MDM_Field__c.toLowerCase()), mdmFieldMapping);
            system.debug('not coming');
            if (!idsByNameByLookupField.isEmpty() && mdmFieldMapping.MVN_Is_Lookup_Field__c && idsByNameByLookupField.containsKey(mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase())) {

                Map<String, Id> idsByName = idsByNameByLookupField.get(mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase());
                value = idsByName.get(String.valueOf(value));
            }
            if (value == null) {
                continue;
            }
            hasAnyValue = true;
            thisObject.put(
                mdmFieldMapping.MVN_SFDC_Field__c,
                MVN_MDMConnectionUtil.getValue(
                    sObjectName,
                    mdmFieldMapping.MVN_SFDC_Field__c.toLowerCase(),
                    value
                )
            );
        }
        if (!hasAnyValue) {
            return null;
        }
        return thisObject;
    }

    /**
     * Get Value mapped if there is any MDM Value Mapping defined
     * @param value             MDM Value to be mapped
     * @param mdmFieldMapping   MDM Field Mapping metadata which contains all the MDM Value Mappings related
     * @return  `Object`
     */
    private static Object getValueMapped(Object value, MVN_MDM_Field_Mapping__mdt mdmFieldMapping) {
        if (mdmFieldMapping.MVN_MDM_Value_Mappings__r == null || mdmFieldMapping.MVN_MDM_Value_Mappings__r.isEmpty()) {
            return value;
        }
        for (MVN_MDM_Value_Mapping__mdt mdmValueMapping : mdmFieldMapping.MVN_MDM_Value_Mappings__r) {
            if (mdmValueMapping.MVN_Inbound__c && mdmValueMapping.MVN_MDM_Value__c.toLowerCase() == String.valueOf(value).toLowerCase()) {
                value = mdmValueMapping.MVN_SFDC_Value__c;
            }
        }
        return value;
    }
}