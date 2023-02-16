/**
 * DCR Wrapper to create DCR and Lines related to a record
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCR {
    /**
     * global setting
     */
    public static PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;

    /**
     * SFDC Record Type Id field name
     */
    public static final String RECORD_TYPE_ID_FIELD_NAME = 'RecordTypeId';

    /**
     * Parameter to avoid creating DCR when updating from DCR
     */
    public static Boolean updateFromNetwork = false;

    /**
     * Parent Data change request
     */
    public PJN_Data_Change_Request__c parentDcr;

    /**
     * Record Data change request
     */
    public PJN_Data_Change_Request__c dcr;

    /**
     * Parent Data change request lines
     */
    public List<PJN_Data_Change_Request_Line__c> parentDcrLines = new List<PJN_Data_Change_Request_Line__c>();

    /**
     * Record Data change request lines
     */
    public List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

    /**
     * Record data to revert
     */
    public Map<String, Object> revertValueByFieldName = new Map<String, Object>();

    /**
     * Build DCR and Lines from dcr record provided
     * @param dcr   Data change request and lines provided
     */
    public PJN_DCR(PJN_Data_Change_Request__c dcr) {
        this.dcr = dcr;
        this.dcrLines = dcr.PJN_Data_Change_Request_Lines__r;
    }

    /**
     * Build DCR, Parent DCR and lines from DCR and Parent DCR records provided
     * @param dcr       Data change request and lines provided
     * @param parentDcr Parent data change request and lines provided
     */
    public PJN_DCR(PJN_Data_Change_Request__c dcr, PJN_Data_Change_Request__c parentDcr) {
        this.dcr = dcr;
        this.dcrLines = dcr.PJN_Data_Change_Request_Lines__r;
        this.parentDcr = parentDcr;
        this.parentDcrLines = parentDcr.PJN_Data_Change_Request_Lines__r;
    }

    /**
     * Build DCR and Lines for account record
     * @param oldAccount    Old values for account
     * @param newAccount    New values for account
     */
    public PJN_DCR(Account oldAccount, Account newAccount) {
        if (!getIfDCRAllowed(newAccount)) {
            return;
        }

        String currentRecordTypeDevName = getRecordTypeName(newAccount);
        String dcrType = oldAccount != null ? PJN_NetworkConstants.DCR_TYPE_EDIT : PJN_NetworkConstants.DCR_TYPE_NEW;
        PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName(Account.getSObjectType().getDescribe().getName(), currentRecordTypeDevName);
        String networkObjectName = networkRecordType != null && String.isNotBlank(networkRecordType.PJN_Network_Record_Type__c) ?
            networkRecordType.PJN_Network_Record_Type__c :
            PJN_NetworkConstants.NETWORK_ACCOUNT_TYPE;

        this.dcr = new PJN_Data_Change_Request__c (
            RecordTypeId = Schema.SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByDeveloperName().get(PJN_NetworkConstants.DCR_ACCOUNT).getRecordTypeId(),
            PJN_Account__c = newAccount.Id,
            PJN_Veeva_Network_Id__c = newAccount.PJN_Veeva_Network_Id__c,
            PJN_External_Id__c = getCustomExternalId(networkObjectName, newAccount.Id),
            PJN_Record_Type_Name__c = currentRecordTypeDevName,
            PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_PENDING,
            PJN_Type__c = dcrType
        );

        this.dcrLines = buildDCRLines(oldAccount, newAccount);
    }

    /**
     * Build DCR and Lines for Address
     * Needs Parent DCR for Account
     * @param parentAccount Parent account record related to the address
     * @param oldAddress    Old values for address
     * @param newAddress    New values for address
     */
    public PJN_DCR(Account parentAccount, PJN_Contact_Information__c oldAddress, PJN_Contact_Information__c newAddress) {
        if (!getIfDCRAllowed(newAddress)) {
            return;
        }

        String currentRecordTypeDevName = getRecordTypeName(newAddress);
        String dcrType = oldAddress != null ? PJN_NetworkConstants.DCR_TYPE_EDIT : PJN_NetworkConstants.DCR_TYPE_NEW;
        PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName(PJN_Contact_Information__c.getSObjectType().getDescribe().getName(), currentRecordTypeDevName);
        String networkObjectName = networkRecordType != null && String.isNotBlank(networkRecordType.PJN_Network_Record_Type__c) ?
            networkRecordType.PJN_Network_Record_Type__c :
            PJN_NetworkConstants.NETWORK_ADDRESS_TYPE;

        List<PJN_Network_Parent_Object_Filter__mdt> networkParentFilters = PJN_NetworkObjectSetting.getParentFiltersByNameAndRecordType(PJN_Contact_Information__c.sObjectType.getDescribe().getName(), currentRecordTypeDevName);
        Boolean isParentAllowed = PJN_DCRCreateHelper.isParentObjectFilterAllowed(networkParentFilters, parentAccount);

        if (!isParentAllowed) {
            return;
        }

        this.parentDcr = buildParentAccountDCR(parentAccount);

        if (this.parentDcr == null) {
            return;
        }

        this.dcr = new PJN_Data_Change_Request__c (
            RecordTypeId = Schema.SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByDeveloperName().get(PJN_NetworkConstants.DCR_ADDRESS).getRecordTypeId(),
            PJN_Contact_Information__c = newAddress.Id,
            PJN_Veeva_Network_Id__c = newAddress.PJN_Veeva_Network_Id__c,
            PJN_External_Id__c = getCustomExternalId(networkObjectName, newAddress.Id),
            PJN_Record_Type_Name__c = currentRecordTypeDevName,
            PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_PENDING,
            PJN_Type__c = dcrType,
            PJN_Parent_Data_Change_Request__r = new PJN_Data_Change_Request__c(
                PJN_External_Id__c = this.parentDcr.PJN_External_Id__c
            )
        );

        this.parentDcrLines = buildParentDCRLines(parentAccount);
        this.dcrLines = buildDCRLines(oldAddress, newAddress);
    }

    /**
     * Build DCR and Lines for License
     * Needs Parent DCR for Account
     * @param parentAccount Parent account record related to the license
     * @param oldLicense    Old values for license
     * @param newLicense    New values for license
     */
    public PJN_DCR(Account parentAccount, PJN_License__c oldLicense, PJN_License__c newLicense) {
        if (!getIfDCRAllowed(newLicense)) {
            return;
        }

        String currentRecordTypeDevName = getRecordTypeName(newLicense);
        String dcrType = oldLicense != null ? PJN_NetworkConstants.DCR_TYPE_EDIT : PJN_NetworkConstants.DCR_TYPE_NEW;
        PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName(PJN_License__c.getSObjectType().getDescribe().getName(), currentRecordTypeDevName);
        String networkObjectName = networkRecordType != null && String.isNotBlank(networkRecordType.PJN_Network_Record_Type__c) ?
            networkRecordType.PJN_Network_Record_Type__c :
            null;

        List<PJN_Network_Parent_Object_Filter__mdt> networkParentFilters = PJN_NetworkObjectSetting.getParentFiltersByNameAndRecordType(PJN_License__c.sObjectType.getDescribe().getName(), currentRecordTypeDevName);
        Boolean isParentAllowed = PJN_DCRCreateHelper.isParentObjectFilterAllowed(networkParentFilters, parentAccount);

        if (!isParentAllowed) {
            return;
        }

        this.parentDcr = buildParentAccountDCR(parentAccount);

        if (this.parentDcr == null) {
            return;
        }

        this.dcr = new PJN_Data_Change_Request__c (
            RecordTypeId = Schema.SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByDeveloperName().get(PJN_NetworkConstants.DCR_LICENSE).getRecordTypeId(),
            PJN_License__c = newLicense.Id,
            PJN_License_Address__c = newLicense.PJN_Contact_Information__c,
            PJN_Veeva_Network_Id__c = newLicense.PJN_Veeva_Network_Id__c,
            PJN_External_Id__c = getCustomExternalId(PJN_NetworkConstants.NETWORK_LICENSE_TYPE, newLicense.Id),
            PJN_Record_Type_Name__c = currentRecordTypeDevName,
            PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_PENDING,
            PJN_Type__c = dcrType,
            PJN_Parent_Data_Change_Request__r = new PJN_Data_Change_Request__c(
                PJN_External_Id__c = this.parentDcr.PJN_External_Id__c
            )
        );

        this.parentDcrLines = buildParentDCRLines(parentAccount);
        this.dcrLines = buildDCRLines(oldLicense, newLicense);
    }

    public void addLicenseAddress(PJN_Contact_Information__c thisAddress) {
        if (thisAddress == null) {
            return;
        }

        this.dcr.PJN_License_Address_Network_Id__c = thisAddress.PJN_Veeva_Network_Id__c;
    }

    /**
     * Get if current record is allowed to create a DCR according to Network Object settings
     * @param record    Current record to verify
     * @returns `Boolean`
     */
    private static Boolean getIfDCRAllowed(SObject record) {
        if (updateFromNetwork) {
            return false;
        }

        Boolean isDCRCreationAllowed = pjnSetting != null ? pjnSetting.PJN_Create_DCR__c : false;
        if (!isDCRCreationAllowed) {
            return false;
        }

        Schema.DescribeSObjectResult recordDescribe = record.getSObjectType().getDescribe();

        PJN_Network_Object_Setting__mdt networkObjectSetting = PJN_NetworkObjectSetting.getSettingByName(recordDescribe.getName());

        if (networkObjectSetting == null) {
            return false;
        }

        if (!recordDescribe.fields.getMap().keySet().contains(RECORD_TYPE_ID_FIELD_NAME.toLowerCase())) {
            return true;
        }

        String recordTypeDevName = recordDescribe.getRecordTypeInfosById().get(String.valueOf(record.get(RECORD_TYPE_ID_FIELD_NAME))).getDeveloperName();

        if (String.isBlank(networkObjectSetting.PJN_DCR_Record_Types_Allowed__c)) {
            return false;
        }

        List<String> recordTypesAllowed = networkObjectSetting.PJN_DCR_Record_Types_Allowed__c.replaceAll('\\s+', '').split(',');

        return recordTypesAllowed.contains('All') || recordTypesAllowed.contains(recordTypeDevName);
    }

    /**
     * Generate and get custom external id for Veeva Network
     * @param networkEntityType Veeva network entity type
     * @param networkObjectName Veeva network Object name
     * @param recordId          Current record id
     * @returns `String`
     */
    private String getCustomExternalId(String networkObjectName, Id recordId) {
        String systemName = pjnSetting != null ? pjnSetting.PJN_Network_System__c : PJN_NetworkConstants.NETWORK_SYSTEM;

        return String.format(
            '{0}:{1}:{2}|{3}',
            new List<String> {
                systemName,
                networkObjectName,
                recordId,
                PJN_NetworkConstants.DCR_STATUS_PENDING
            }
        );
    }

    /**
     * Build Parent DCR for account related to actual record
     * @param parentAccount Parent Account record related
     * @returns `PJN_Data_Change_Request__c`
     */
    private PJN_Data_Change_Request__c buildParentAccountDCR(Account parentAccount) {
        if (parentAccount == null) {
            return null;
        }

        if (!getIfDCRAllowed(parentAccount)) {
            return null;
        }

        String currentRecordTypeDevName = getRecordTypeName(parentAccount);
        PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName(Account.getSObjectType().getDescribe().getName(), currentRecordTypeDevName);
        String networkObjectName = networkRecordType != null && String.isNotBlank(networkRecordType.PJN_Network_Record_Type__c) ?
            networkRecordType.PJN_Network_Record_Type__c :
            PJN_NetworkConstants.NETWORK_ACCOUNT_TYPE;

        return new PJN_Data_Change_Request__c (
            RecordTypeId = Schema.SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByDeveloperName().get(PJN_NetworkConstants.DCR_ACCOUNT).getRecordTypeId(),
            PJN_Account__c = parentAccount.Id,
            PJN_Veeva_Network_Id__c = parentAccount.PJN_Veeva_Network_Id__c,
            PJN_External_Id__c = getCustomExternalId(networkObjectName, parentAccount.Id),
            PJN_Record_Type_Name__c = currentRecordTypeDevName,
            PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_PENDING,
            PJN_Type__c = PJN_NetworkConstants.DCR_TYPE_EDIT
        );
    }

    /**
     * Build Parent DCR Lines for account related to actual record
     * @param parentAccount Parent Account record related
     * @returns `List<PJN_Data_Change_Request_Line__c>`
     */
    private List<PJN_Data_Change_Request_Line__c> buildParentDCRLines(Account parentAccount) {
        List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

        // If Network Id on DCR - Required fields are not needed
        if (parentAccount == null || String.isNotBlank(parentAccount.PJN_Veeva_Network_Id__c)) {
            return dcrLines;
        }

        Map<String,Schema.SObjectField> accountFields = Account.sObjectType.getDescribe().fields.getMap();

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(Account.sObjectType.getDescribe().getName(), parentAccount.RecordType.DeveloperName)) {
            if (!networkFieldMapping.PJN_Required_for_DCR_Transmission__c || !NetworkFieldMapping.PJN_DCR_Transmission__c) {
                continue;
            }

            dcrLines.add(
                new PJN_Data_Change_Request_Line__c(
                    PJN_Account__c = parentAccount.Id,
                    PJN_Field_Label__c = accountFields.get(networkFieldMapping.PJN_Field_API_Name__c).getDescribe().getLabel(),
                    PJN_Field_API_Name__c = networkFieldMapping.PJN_Field_API_Name__c,
                    PJN_Old_Value__c = String.valueOf(parentAccount.get(networkFieldMapping.PJN_Field_API_Name__c)),
                    PJN_New_Value__c = String.valueOf(parentAccount.get(networkFieldMapping.PJN_Field_API_Name__c)),
                    PJN_Data_Change_Request__r = new PJN_Data_Change_Request__c(
                        PJN_External_Id__c = this.parentDcr.PJN_External_Id__c
                    )
                )
            );
        }

        return dcrLines;
    }

    /**
     * Buid DCR Lines for record
     * @param oldRecord Old values for record
     * @param newRecord New values for record
     * @returns `List<PJN_Data_Change_Request_Line__c>`
     */
    private List<PJN_Data_Change_Request_Line__c> buildDCRLines(Sobject oldRecord, SObject newRecord) {
        List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

        Schema.DescribeSObjectResult recordDescribe = newRecord.getSObjectType().getDescribe();

        Map<String,Schema.SObjectField> recordFields = recordDescribe.fields.getMap();
        String recordObjectName = recordDescribe.getName();
        String recordTypeDevName = recordFields.keySet().contains(RECORD_TYPE_ID_FIELD_NAME.toLowerCase()) ?
            recordDescribe.getRecordTypeInfosById().get(String.valueOf(newRecord.get(RECORD_TYPE_ID_FIELD_NAME))).getDeveloperName():
            null;

        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = String.IsNotBlank(recordTypeDevName) ?
            PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(recordObjectName, recordTypeDevName) :
            PJN_NetworkObjectSetting.getMappingsByName(recordObjectName);

        Boolean hasAnyChange = false;

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
            Boolean hasChanged = oldRecord == null ||
                (oldRecord.get(networkFieldMapping.PJN_Field_API_Name__c) != newRecord.get(networkFieldMapping.PJN_Field_API_Name__c));

            hasAnyChange = hasAnyChange || hasChanged;

            Boolean hasChangedOrRequired = hasChanged || networkFieldMapping.PJN_Required_for_DCR_Transmission__c;

            if (!hasChangedOrRequired || !networkFieldMapping.PJN_DCR_Transmission__c) {
                continue;
            }

            Object oldValue = (oldRecord != null ? oldRecord.get(networkFieldMapping.PJN_Field_API_Name__c) : null);

            if (networkFieldMapping.PJN_DCR_Update_After_Approval__c) {
                revertValueByFieldName.put(networkFieldMapping.PJN_Field_API_Name__c, oldValue);
            }

            dcrLines.add(
                new PJN_Data_Change_Request_Line__c(
                    PJN_Account__c = this.dcr.PJN_Account__c,
                    PJN_Contact_Information__c = this.dcr.PJN_Contact_Information__c,
                    PJN_License__c = this.dcr.PJN_License__c,
                    PJN_Field_Label__c = recordFields.get(networkFieldMapping.PJN_Field_API_Name__c).getDescribe().getLabel(),
                    PJN_Field_API_Name__c = networkFieldMapping.PJN_Field_API_Name__c,
                    PJN_Old_Value__c = String.valueOf(oldValue),
                    PJN_New_Value__c = String.valueOf(newRecord.get(networkFieldMapping.PJN_Field_API_Name__c)),
                    PJN_Data_Change_Request__r = new PJN_Data_Change_Request__c(
                        PJN_External_Id__c = this.dcr.PJN_External_Id__c
                    )
                )
            );
        }

        if (!hasAnyChange) {
            return new List<PJN_Data_Change_Request_Line__c>();
        }

        return dcrLines;
    }

    /**
     * Get record associated record type developer name
     * @param record    Record used to maps record type
     * @returns `String`
     */
    private String getRecordTypeName(SObject record) {
        Schema.DescribeSObjectResult recordDescribe = record.getSObjectType().getDescribe();

        return recordDescribe.fields.getMap().keySet().contains(RECORD_TYPE_ID_FIELD_NAME.toLowerCase()) ?
            recordDescribe.getRecordTypeInfosById().get(String.valueOf(record.get(RECORD_TYPE_ID_FIELD_NAME))).getDeveloperName():
            null;
    }
}