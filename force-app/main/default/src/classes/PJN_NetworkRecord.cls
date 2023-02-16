/**
 * Veeva Network entity or child format
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkRecord {

    /**
     * Decides if reserve Veeva Network Id sending DCR
     */
    public Boolean reserveVid;

    /**
     * The external record vid_key supplied by the client.
     */
    public String vidKey;

    /**
     * The ID of the network record
     */
    public String vid;

    /**
     * The external license address vid_key supplied by the client.
     */
    public String licenseAddressVidKey;

    /**
     * The external license address vid supplied by the client.
     */
    public String licenseAddressVid;

    /**
     * Network Record Type
     */
    public String entityType;

    /**
     *
     */
    private String objectId;

    /**
     * Network fields
     */
    public Map<String, Object> attributes;

    /**
     * An array of change requests for addresses, one per address, for the entity provided
     */
    public List<PJN_NetworkRecord> addresses;

    /**
     * An array of change requests for licenses, one per license, for the entity provided
     */
    public List<PJN_NetworkRecord> licenses;

    /**
     * An array of change requests for affiliations, one per affiliation, for the entity provided
     */
    public List<PJN_NetworkRecord> affiliations;

    /**
     * Constructor of Network DCR structure using DCR Wrapper
     * @param dcrWrapper
     */
    public PJN_NetworkRecord(PJN_DCR dcrWrapper) {
        Boolean isParentDCR = dcrWrapper.parentDcr != null;

        PJN_Data_Change_Request__c entityDCR = isParentDCR ? dcrWrapper.parentDcr : dcrWrapper.dcr;
        List<PJN_Data_Change_Request_Line__c> entityDCRLines = isParentDCR ? dcrWrapper.parentDcrLines : dcrWrapper.dcrLines;

        this.reserveVid = String.isBlank(entityDCR.PJN_Veeva_Network_Id__c);
        this.vid = entityDCR.PJN_Veeva_Network_Id__c;

        this.vidKey = String.isNotBlank(entityDCR.PJN_Veeva_Network_Id__c) ?
            'Network:' + getNetworkEntityString(entityDCR) + ':' + this.vid :
            entityDCR.PJN_External_Id__c.substringBeforeLast('|');

        this.entityType = String.isNotBlank(entityDCR.PJN_Record_Type_Name__c) ?
            entityDCR.PJN_Record_Type_Name__c :
            Account.getSObjectType().getDescribe().getRecordTypeInfosById().get(entityDCR.PJN_Account__r.RecordTypeId).getDeveloperName();

        addAttributes(Account.getSObjectType().getDescribe().getName(), this.entityType, entityDCRLines);

        this.addresses = new List<PJN_NetworkRecord>();
        this.licenses = new List<PJN_NetworkRecord>();
        this.affiliations = new List<PJN_NetworkRecord>();
    }

    public PJN_NetworkRecord(Schema.DescribeSObjectResult sobjectDescribe, PJN_Data_Change_Request__c dcr, List<PJN_Data_Change_Request_Line__c> dcrLines) {
        this.reserveVid = String.isNotBlank(dcr.PJN_Veeva_Network_Id__c);

        this.vid = dcr.PJN_Veeva_Network_Id__c;
        this.vidKey = String.isNotBlank(dcr.PJN_Veeva_Network_Id__c) ?
            'Network:' + getNetworkEntityString(dcr) + ':' + this.vid :
            dcr.PJN_External_Id__c.substringBeforeLast('|');

        if (String.isNotBlank(dcr.PJN_Record_Type_Name__c)) {
            this.entityType = dcr.PJN_Record_Type_Name__c;
        } else if (sobjectDescribe.getRecordTypeInfosById() != null && !sobjectDescribe.getRecordTypeInfosById().isEmpty()) {
            String recordTypeId;
            if (dcr.PJN_Contact_Information__c != null) {
                recordTypeId = dcr.PJN_Contact_Information__r.RecordTypeId;
            } else if (dcr.PJN_License__c != null) {
                recordTypeId = dcr.PJN_License__r.RecordTypeId;
            }

            this.entityType = sobjectDescribe.getRecordTypeInfosById().get(recordTypeId).getDeveloperName();
        }

        if (String.IsNotBlank(dcr.PJN_License_Address__c)) {
            String systemName = PJN_DCR.pjnSetting != null ? PJN_DCR.pjnSetting.PJN_Network_System__c : PJN_NetworkConstants.NETWORK_SYSTEM;
            this.licenseAddressVidKey = String.IsNotBlank(dcr.PJN_License_Address_Network_Id__c) ?
                'Network:' + PJN_NetworkConstants.NETWORK_ADDRESS_TYPE + ':' + dcr.PJN_License_Address_Network_Id__c :
                systemName + ':' + PJN_NetworkConstants.NETWORK_ADDRESS_TYPE + ':' + dcr.PJN_License_Address__c;
        }

        addAttributes(sobjectDescribe.getName(), this.entityType, dcrLines);
    }

    private Map<String, PJN_Network_Field_Mapping__mdt> getNetworkFieldMappingsByFieldName(List<PJN_Network_Field_Mapping__mdt> networkFieldMappings) {
        Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingsByFieldName = new Map<String, PJN_Network_Field_Mapping__mdt>();

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
            networkFieldMappingsByFieldName.put(networkFieldMapping.PJN_Field_API_Name__c, networkFieldMapping);
        }

        return networkFieldMappingsByFieldName;
    }

    /**
     * Add child dcr records to Network structure
     * @param dcrWrapper    DCR Wrapper to retrieves the child record
     */
    public void addChildDCR(PJN_DCR dcrWrapper) {
        if (dcrWrapper.dcr.PJN_Contact_Information__c != null) {
            this.addresses.add(new PJN_NetworkRecord(PJN_Contact_Information__c.getSObjectType().getDescribe(), dcrWrapper.dcr, dcrWrapper.dcrLines));
        } else if (dcrWrapper.dcr.PJN_License__c != null) {
            this.licenses.add(new PJN_NetworkRecord(PJN_License__c.getSObjectType().getDescribe(), dcrWrapper.dcr, dcrWrapper.dcrLines));
        }
    }

    /**
     * Veeva Network Entity or child constructor using Network response provided
     * @param entityResponse    Network entity response
     */
    public PJN_NetworkRecord(Map<String, Object> entityResponse) {
        this.attributes = entityResponse;

        this.vidKey = String.valueOf(entityResponse.get('vid_key'));
        this.vid = String.valueOf(entityResponse.get('vid__v'));
        this.objectId = String.valueOf(entityResponse.get('object_id'));
        this.licenseAddressVidKey = entityResponse.get(PJN_NetworkConstants.NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD) != null && String.valueOf(entityResponse.get(PJN_NetworkConstants.NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD)).contains('final_value') ?
            String.valueOf(((Map<String, Object>) entityResponse.get(PJN_NetworkConstants.NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD)).get('final_value')) :
            String.valueOf(entityResponse.get(PJN_NetworkConstants.NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD));
        this.licenseAddressVid = String.valueOf(entityResponse.get(PJN_NetworkConstants.NETWORK_SYNC_LICENSE_ADDRESS_ID_FIELD));
        this.entityType = String.valueOf(entityResponse.get('type__v'));

        this.addresses = getNetworkChildren('addresses__v');
        this.licenses = getNetworkChildren('licenses__v');
        this.affiliations = getNetworkChildren('parent_hcos__v');
    }

    /**
     * Initialize children from Network response
     * @param childrenParamName Children parameter name on Network response
     * @returns `List<PJN_NetworkRecord>`
     */
    private List<PJN_NetworkRecord> getNetworkChildren(String childrenParamName) {
        List<PJN_NetworkRecord> networkChildren = new List<PJN_NetworkRecord>();

        if (!attributes.containsKey(childrenParamName)) {
            return networkChildren;
        }

        for (Object networkResponseChild : (List<Object>) attributes.get(childrenParamName)) {
            networkChildren.add(new PJN_NetworkRecord((Map<String, Object>) networkResponseChild));
        }

        return networkChildren;
    }

    /**
     * Get Network attribute
     * @param fieldName External Network Field name
     * @returns `String`
    */
    public String getAttribute(String fieldName) {
        return this.attributes != null && this.attributes.containsKey(fieldName) ?
            String.valueOf(this.attributes.get(fieldName)) :
            null;
    }

    public String getNetworkEntityString(PJN_Data_Change_Request__c dcr) {
        String dcrRecordDevName = PJN_Data_Change_Request__c.getSObjectType().getDescribe().getRecordTypeInfosById().get(dcr.RecordTypeId).getDeveloperName();

        switch on dcrRecordDevName {
            when 'PJN_Account' {
                return 'Entity';
            } when 'PJN_Affiliation' {
                return 'ParentHCO';
            } when 'PJN_Contact_Information' {
                return 'PJN_Address';
            } when 'PJN_License' {
                return 'License';
            } when else {
                return '';
            }
        }
    }

    private void addAttributes(String sobjectName, String recordTypeName, List<PJN_Data_Change_Request_Line__c> dcrLines) {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings;

        if (String.IsNotBlank(recordTypeName)) {
            networkFieldMappings = PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(sobjectName, recordTypeName);

            PJN_Network_Record_Type_Mapping__mdt networkRecordTypeMapping = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName(sobjectName, recordTypeName);

            this.entityType = networkRecordTypeMapping != null ? networkRecordTypeMapping.PJN_Network_Record_Type__c : null;
        } else {
            networkFieldMappings = PJN_NetworkObjectSetting.getMappingsByName(sobjectName);
        }

        Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingsByFieldName = getNetworkFieldMappingsByFieldName(networkFieldMappings);

        this.attributes = new Map<String, Object>();

        for (PJN_Data_Change_Request_Line__c dcrLine : dcrLines) {
            PJN_Network_Field_Mapping__mdt currentNetworkFieldMapping = networkFieldMappingsByFieldName.get(dcrLine.PJN_Field_API_Name__c);

            if (currentNetworkFieldMapping == null) {
                continue;
            }

            String newValue = dcrLine.PJN_New_Value__c;

            if (currentNetworkFieldMapping.PJN_Network_Value_Mappings__r != null) {
                for (PJN_Network_Value_Mapping__mdt valueMapping : currentNetworkFieldMapping.PJN_Network_Value_Mappings__r) {
                    if (valueMapping.PJN_Outbound__c && valueMapping.PJN_Value__c.equalsIgnoreCase(newValue)) {
                        newValue = valueMapping.PJN_External_Value__c;
                        break;
                    }
                }
            }

            this.attributes.put(currentNetworkFieldMapping.PJN_External_Field_Name__c, newValue);
        }
    }
}