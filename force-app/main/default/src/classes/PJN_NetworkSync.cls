/**
 * Network sync records using Network Id
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkSync {
    /**
     * global setting
     */
    public static PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;

    /**
     * Parameter to define if record was updated from network
     */
    private Boolean isUpdated;

    /**
     *
     */
    private Boolean isNetworkAllowed = pjnSetting != null ? pjnSetting.PJN_Veeva_Network__c : false;

    /**
     * Account record
     */
    private List<Account> accounts;

    /**
     * Account record
     */
    private List<PJN_Data_Change_Request__c> dcrs;

    /**
     * Network callout for sync
     */
    private PJN_NetworkCallout networkCallout;

    /**
     * Affiliation object settings
     */
    PJN_Network_Object_Setting__mdt networkAffilitionSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_Affiliation__c');


    /**
     * Sync body
     */
    private String syncBody;

    private List<Account> updateAccounts = new List<Account>();
    private List<PJN_Contact_Information__c> updateAddresses = new List<PJN_Contact_Information__c>();
    private List<PJN_License__c> updateLicenses = new List<PJN_License__c>();
    private List<PJN_Affiliation__c> updateAffiliations = new List<PJN_Affiliation__c>();

    private List<PJN_Data_Change_Request__c> dcrsToUpdate = new List<PJN_Data_Change_Request__c>();
    private List<PJN_Data_Change_Request_Line__c> dcrLinesToUpdate = new List<PJN_Data_Change_Request_Line__c>();

    /**
     * Contructor to initialize network sync and querying the account and children
     * @param accountId Account Id to obtain account and children
     */
    public PJN_NetworkSync(String accountId) {
        this.isUpdated = false;

        if (!this.isNetworkAllowed || accountId == null) {
            return;
        }

        initializeNetworkSync(new Set<String> {accountId});
    }

    /**
     * Contructor to initialize network sync and querying the account and children
     * @param accountId Account Id to obtain account and children
     */
    public PJN_NetworkSync(Set<String> accountIds) {
        this.isUpdated = false;

        if (!isNetworkAllowed) {
            return;
        }

        initializeNetworkSync(accountIds);
    }

    private void initializeNetworkSync(Set<String> accountIds) {
        List<Account> queriedAccounts = PJN_NetworkSyncUtility.queryAccounts(accountIds);

        if (queriedAccounts == null || queriedAccounts.isEmpty()) {
            return;
        }

        this.accounts = new List<Account>();
        this.dcrs = new List<PJN_Data_Change_Request__c>();

        String accountRecordTypesAllowed = PJN_NetworkObjectSetting.getSettingByName('Account').PJN_Sync_Record_Types_Allowed__c.toLowerCase();

        for (Account queriedAccount : queriedAccounts) {
            Boolean isNetworkAllowed = accountRecordTypesAllowed.contains('all') || accountRecordTypesAllowed.contains(queriedAccount.RecordType.DeveloperName.toLowerCase());

            if (queriedAccount.PJN_Data_Change_Requests__r != null && !queriedAccount.PJN_Data_Change_Requests__r.isEmpty()) {
                this.dcrs.addAll(queriedAccount.PJN_Data_Change_Requests__r);
            } else if (isNetworkAllowed) {
                this.accounts.add(queriedAccount);
            }
        }
    }

    /**
     * Call Network sync and retrieve all information for account and children updating those
     * @returns `Boolean`
     */
    public Boolean sync() {
        this.isUpdated = false;

        if (!this.isNetworkAllowed) {
            return isUpdated;
        }

        if (this.accounts != null && !this.accounts.isEmpty()) {
            this.isUpdated = syncAccounts(this.isUpdated);
        }

        if (this.dcrs != null && !this.dcrs.isEmpty()) {
            this.isUpdated = syncDCRs(this.isUpdated);
        }

        PJN_DCR.updateFromNetwork = true;
        update updateAccounts;
        upsert updateAddresses;
        upsert updateLicenses;
        upsert updateAffiliations;
        update dcrLinesToUpdate;
        update dcrsToUpdate;

        return isUpdated;
    }

    private Boolean syncAccounts(Boolean isUpdated) {
        PJN_PublishTransactionLog.logType = 'Sync';

        initRecordNetworkSync();

        PJN_NetworkResponse networkResponse;

        try {
            networkResponse = networkCallout.callVeevaNetwork(syncBody);
        } catch(PJN_NetworkCallout.NetworkCalloutException networkException) {
            networkResponse = new PJN_NetworkResponse(
                new Map<String, Object> {
                    'responseStatus' => PJN_NetworkConstants.NETWORK_FAILURE,
                    'responseMessage' => networkException.getMessage()
                }
            );
        }

        if (networkResponse != null && networkResponse.responseStatus == PJN_NetworkConstants.NETWORK_SUCCESS) {
            isUpdated = updateRecordsWithResponse(networkResponse);
        }

        return isUpdated;
    }

    private void initRecordNetworkSync() {
        this.networkCallout = new PJN_NetworkCallout('/entities/batch', 'POST', 'application/json');

        List<Object> entities = new List<Object>();
        for (Account thisAccount : this.accounts) {
            entities.add(
                new Map<String, Object> {
                    'vid_key' => thisAccount.PJN_Veeva_Network_Id__c
                }
            );
        }
        this.syncBody = System.JSON.serialize(
            new Map<String, Object> {
                'entities' => entities
            },
            true
        );
    }

    private Boolean syncDCRs(Boolean isUpdated) {
        PJN_PublishTransactionLog.logType = 'Sync';

        initDCRNetworkSync();

        if (String.IsBlank(this.syncBody)) {
            return isUpdated;
        }

        PJN_NetworkResponse networkResponse;

        try {
            networkResponse = networkCallout.callVeevaNetwork(syncBody);
        } catch(PJN_NetworkCallout.NetworkCalloutException networkException) {
            networkResponse = new PJN_NetworkResponse(
                new Map<String, Object> {
                    'responseStatus' => PJN_NetworkConstants.NETWORK_FAILURE,
                    'responseMessage' => networkException.getMessage()
                }
            );
        }

        if (networkResponse != null && networkResponse.responseStatus == PJN_NetworkConstants.NETWORK_SUCCESS) {
            isUpdated = updateDCRsWithResponse(networkResponse);
        }

        return isUpdated;
    }

    private void initDCRNetworkSync() {
        this.networkCallout = new PJN_NetworkCallout('/change_requests/batch', 'POST', 'application/json');

        List<Object> changeRequests = new List<Object>();
        for (PJN_Data_Change_Request__c thisDCR : this.dcrs) {
            if (thisDCR.PJN_Status__c != PJN_NetworkConstants.DCR_STATUS_SUBMITTED) {
                continue;
            }

            changeRequests.add(
                new Map<String, Object> {
                    'change_request_id' => thisDCR.PJN_DCR_External_ID__c
                }
            );
        }

        if (changeRequests.isEmpty()) {
            return;
        }

        this.syncBody = System.JSON.serialize(
            new Map<String, Object> {
                'change_requests' => changeRequests
            },
            true
        );
    }

    /**
     * Update records with results from Veeva Network
     * @param networkResponse   Veeva Network records method response
     */
    private Boolean updateRecordsWithResponse(PJN_NetworkResponse networkResponse) {
        Boolean isUpdated = false;
        Map<String, Map<String, PJN_NetworkRecord>> recordByNetworkIdByAccExtId = PJN_NetworkSyncUtility.getRecordByNetworkIdsByExtId(networkResponse.entities);

        PJN_Network_Object_Setting__mdt networkAccountSetting = PJN_NetworkObjectSetting.getSettingByName('Account');

        for (Account thisAccount : accounts) {
            Map<String, PJN_NetworkRecord> recordByNetworkId = recordByNetworkIdByAccExtId.get(thisAccount.PJN_Veeva_Network_Id__c);

            if (recordByNetworkId == null || recordByNetworkId.isEmpty()) {
                continue;
            }

            PJN_NetworkRecord accountNetworkRecord = recordByNetworkId.get(thisAccount.PJN_Veeva_Network_Id__c);

            thisAccount = PJN_NetworkSyncUtility.updateLastModifiedDate(thisAccount, accountNetworkRecord);

            Boolean allowedToSync = PJN_NetworkSyncUtility.isAccountAllowedToSync(thisAccount, networkAccountSetting);

            if (!allowedToSync) {
                continue;
            }

            for (PJN_Network_Field_Mapping__mdt fieldMapping : PJN_NetworkObjectSetting.getMappingsByNameAndRecordType('Account', thisAccount.RecordType.DeveloperName)) {
                if (!fieldMapping.PJN_Sync_Transmission__c) {
                    continue;
                }

                Object entityValue = String.valueOf(accountNetworkRecord.getAttribute(fieldMapping.PJN_External_Field_Name__c));
                entityValue = PJN_NetworkSyncUtility.getEntityValueMapped(fieldMapping.PJN_Network_Value_Mappings__r, entityValue);

                thisAccount.put(fieldMapping.PJN_Field_API_Name__c, entityValue);
            }

            thisAccount.PJN_Last_Date_Network_Synced__c = System.now();

            updateAccounts.add(thisAccount);
            updateAddresses.addAll(buildOrUpdateAddresses(thisAccount, accountNetworkRecord.addresses, recordByNetworkId));
            updateLicenses.addAll(buildOrUpdateLicenses(thisAccount, accountNetworkRecord.licenses, recordByNetworkId));
            updateAffiliations.addAll(buildOrUpdateAffiliations(thisAccount, accountNetworkRecord.affiliations, recordByNetworkId));
            isUpdated = true;
        }

        recalculateAffiliationsWithId();

        return isUpdated;
    }

    /**
     * Update DCRs with results from Veeva Network
     * @param networkResponse   Veeva Network DCRs method response
     */
    private Boolean updateDCRsWithResponse(PJN_NetworkResponse networkResponse) {
        Boolean isUpdated = false;
        Map<String, Map<String, PJN_Data_Change_Request__c>> dcrsByExtId = PJN_NetworkSyncUtility.getDCRsByExtIdFromNetworkResponse(networkResponse.changeRequests);

        for (PJN_NetworkEntity networkChangeRequest : networkResponse.changeRequests) {
            if (String.isBlank(networkChangeRequest.changeRequestId)) {
                continue;
            }

            Map<String, PJN_Data_Change_Request__c> dcrsByRecordId = dcrsByExtId.get(networkChangeRequest.changeRequestId);

            if (dcrsByRecordId == null || dcrsByRecordId.isEmpty()) {
                continue;
            }

            String newStatus = PJN_NetworkStatusMapping.getMessageForNetwokStatus(networkChangeRequest.status);
            String newResult = PJN_NetworkStatusMapping.getMessageForNetwokStatus(networkChangeRequest.result);

            for (String recordExtId : dcrsByRecordId.keySet()) {
                PJN_Data_Change_Request__c currentDCR = dcrsByRecordId.get(recordExtId);
                Map<String, Object> currentChangeRequestAttrs;
                List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();
                Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingByNetworkFieldName = new Map<String, PJN_Network_Field_Mapping__mdt>();

                if (currentDCR.PJN_Account__c != null && (recordExtId == networkChangeRequest.entityId || recordExtId == networkChangeRequest.changeRequestId)) {
                    currentDCR.PJN_Veeva_Network_Id__c = networkChangeRequest.entityId;
                    currentChangeRequestAttrs = networkChangeRequest.entity.attributes;
                    networkFieldMappings = PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(Account.getSObjectType().getDescribe().getName(), currentDCR.PJN_Account__r.RecordType.DeveloperName);
                } else {
                    List<PJN_NetworkRecord> allChildren = new List<PJN_NetworkRecord>();
                    if (currentDCR.PJN_Contact_Information__c != null && networkChangeRequest.entity.addresses != null) {
                        networkFieldMappings = PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(PJN_Contact_Information__c.getSObjectType().getDescribe().getName(), currentDCR.PJN_Contact_Information__r.RecordType.DeveloperName);
                        allChildren.addAll(networkChangeRequest.entity.addresses);
                    }
                    if (currentDCR.PJN_License__c != null && networkChangeRequest.entity.licenses != null) {
                        networkFieldMappings = PJN_NetworkObjectSetting.getMappingsByName(PJN_License__c.getSObjectType().getDescribe().getName());
                        allChildren.addAll(networkChangeRequest.entity.licenses);
                    }

                    for (PJN_NetworkRecord networkChild : allChildren) {
                        if (recordExtId == networkChild.vidKey || recordExtId == networkChild.vid) {
                            currentDCR.PJN_DCR_External_Id__c = currentDCR.Id;
                            currentDCR.PJN_Veeva_Network_Id__c = String.isNotBlank(currentDCR.PJN_Veeva_Network_Id__c) ? currentDCR.PJN_Veeva_Network_Id__c : networkChild.vid;

                            currentDCR.PJN_License_Address_Network_Id__c = networkChild.licenseAddressVidKey;

                            currentChangeRequestAttrs = networkChild.attributes;
                            break;
                        }
                    }
                }

                if (currentChangeRequestAttrs == null || currentChangeRequestAttrs.isEmpty()) {
                    continue;
                }

                for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
                    networkFieldMappingByNetworkFieldName.put(networkFieldMapping.PJN_Field_API_Name__c, networkFieldMapping);
                }

                dcrLinesToUpdate.addAll(getDCRLinesToUpdateForCurrentDCR(currentDCR.PJN_Data_Change_Request_Lines__r, currentChangeRequestAttrs, networkFieldMappingByNetworkFieldName));

                currentDCR.PJN_Status__c = String.isNotBlank(newStatus) ? newStatus : currentDCR.PJN_Status__c;
                currentDCR.PJN_Result__c = newResult;

                dcrsToUpdate.add(currentDCR);
                isUpdated = true;
            }
            isUpdated = true;
        }

        return isUpdated;
    }

    private List<PJN_Data_Change_Request_Line__c> getDCRLinesToUpdateForCurrentDCR(List<PJN_Data_Change_Request_Line__c> dcrLines, Map<String, Object> attributes, Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingByNetworkFieldName) {
        List<PJN_Data_Change_Request_Line__c> dcrLinesToUpdate = new List<PJN_Data_Change_Request_Line__c>();

        Boolean hasAllParams = dcrLines != null && !dcrLines.isEmpty() && attributes != null && !attributes.isEmpty() && networkFieldMappingByNetworkFieldName != null && !networkFieldMappingByNetworkFieldName.isEmpty();

        if (!hasAllParams) {
            return dcrLinesToUpdate;
        }

        for (PJN_Data_Change_Request_Line__c currentDCRLine : dcrLines) {
            PJN_Network_Field_Mapping__mdt currentFieldMapping = networkFieldMappingByNetworkFieldName.get(currentDCRLine.PJN_Field_API_Name__c);

            Map<String, Object> networkDCRLine = attributes.containsKey(currentFieldMapping.PJN_External_Field_Name__c) ?
                (Map<String, Object>) attributes.get(currentFieldMapping.PJN_External_Field_Name__c) :
                new Map<String, Object>();

            if (networkDCRLine.isEmpty()) {
                continue;
            }

            String finalValue = String.valueOf(networkDCRLine.get('final_value'));

            if (currentFieldMapping.PJN_Network_Value_Mappings__r != null) {
                for (PJN_Network_Value_Mapping__mdt valueMapping : currentFieldMapping.PJN_Network_Value_Mappings__r) {
                    if (valueMapping.PJN_Inbound__c && valueMapping.PJN_External_Value__c.equalsIgnoreCase(finalValue)) {
                        finalValue = valueMapping.PJN_Value__c;
                        break;
                    }
                }
            }

            currentDCRLine.PJN_Final_Value__c = finalValue;
            dcrLinesToUpdate.add(currentDCRLine);
        }

        return dcrLinesToUpdate;
    }

    /**
     * Update addresses from network or creating new addresses if need it
     * @param recordByNetworkId Map of network records by veeva network id
     */
    private List<PJN_Contact_Information__c> buildOrUpdateAddresses(Account thisAccount, List<PJN_NetworkRecord> networkAddresses, Map<String, PJN_NetworkRecord> recordByNetworkId) {
        List<PJN_Contact_Information__c> updateAddresses = new List<PJN_Contact_Information__c>();

        PJN_Network_Object_Setting__mdt networkAddressSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_Contact_Information__c');

        if (String.isBlank(networkAddressSetting.PJN_Sync_Record_Types_Allowed__c) || networkAddressSetting.PJN_Sync_Record_Types_Allowed__c.toLowerCase().contains('none')) {
            return updateAddresses;
        }


        List<PJN_Network_Field_Mapping__mdt> fieldMappings = PJN_NetworkObjectSetting.getMappingsByName('PJN_Contact_Information__c');

        Set<String> addressExtIds = new Set<String>();

        for (PJN_Contact_Information__c thisAddress : thisAccount.PJN_Contact_Information__r) {
            Boolean isAllowed = thisAddress.PJN_Veeva_Network_Id__c != null
                && (networkAddressSetting.PJN_Sync_Record_Types_Allowed__c.toLowerCase().contains('all') || networkAddressSetting.PJN_Sync_Record_Types_Allowed__c.toLowerCase().contains(thisAddress.RecordType.DeveloperName.toLowerCase()));

            if (!isAllowed) {
                continue;
            }

            addressExtIds.add(thisAddress.PJN_Veeva_Network_Id__c);
            PJN_NetworkRecord networkRecord = recordByNetworkId.get(thisAddress.PJN_Veeva_Network_Id__c);
            String addressStatus = networkRecord.getAttribute('address_status__v');

            if (String.isBlank(addressStatus) || addressStatus.toLowerCase() != 'a') {
                continue;
            }

            thisAddress = (PJN_Contact_Information__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisAddress, networkRecord, fieldMappings);

            updateAddresses.add(thisAddress);
        }

        for (PJN_NetworkRecord networkAddress : networkAddresses) {
            if (String.isBlank(networkAddress.vid) || addressExtIds.contains(networkAddress.vid)) {
                continue;
            }

            String addressStatus = networkAddress.getAttribute('address_status__v');

            if (String.isBlank(addressStatus) || addressStatus.toLowerCase() != 'a') {
                continue;
            }

            PJN_Contact_Information__c thisAddress = new PJN_Contact_Information__c (
                PJN_Veeva_Network_Id__c = networkAddress.vid,
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
            );

            thisAddress.put(networkAddressSetting.PJN_Parent_Account_Field_Name__c, thisAccount.Id);

            thisAddress = (PJN_Contact_Information__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisAddress, networkAddress, fieldMappings);
            updateAddresses.add(thisAddress);
        }

        return updateAddresses;
    }

    /**
     * Update licenses from network or creating new licenses if need it
     * @param recordByNetworkId Map of network records by veeva network id
     */
    private List<PJN_License__c> buildOrUpdateLicenses(Account thisAccount, List<PJN_NetworkRecord> networkLicenses, Map<String, PJN_NetworkRecord> recordByNetworkId) {
        List<PJN_License__c> updateLicenses = new List<PJN_License__c>();

        PJN_Network_Object_Setting__mdt networkLicenseSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_License__c');

        if (String.isBlank(networkLicenseSetting.PJN_Sync_Record_Types_Allowed__c) || networkLicenseSetting.PJN_Sync_Record_Types_Allowed__c.toLowerCase().contains('none')) {
            return updateLicenses;
        }

        List<PJN_Network_Field_Mapping__mdt> fieldMappings = PJN_NetworkObjectSetting.getMappingsByName('PJN_License__c');

        Set<String> licenseExtIds = new Set<String>();
        Map<String, String> licenseAddressIdByLicenseNetworkId = new Map<String, String>();

        for (PJN_License__c thisLicense : thisAccount.PJN_Licenses__r) {
            if (thisLicense.PJN_Veeva_Network_Id__c == null) {
                continue;
            }

            licenseExtIds.add(thisLicense.PJN_Veeva_Network_Id__c);
            PJN_NetworkRecord networkRecord = recordByNetworkId.get(thisLicense.PJN_Veeva_Network_Id__c);

            String licenseStatus = networkRecord.getAttribute('license_status__v');

            if (String.isBlank(licenseStatus) || licenseStatus.toLowerCase() != 'a') {
                continue;
            }

            thisLicense = (PJN_License__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisLicense, networkRecord, fieldMappings);

            if (String.isNotBlank(networkRecord.entityType)) {
                PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getRecordTypeMappingByObjectAndNetworkRecordTypeName('PJN_License__c', networkRecord.entityType);

                if (networkRecordType != null) {
                    thisLicense.RecordTypeId = Schema.SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get(networkRecordType.PJN_Record_Type_Name__c).getRecordTypeId();
                }
            }

            if (String.isNotBlank(networkRecord.licenseAddressVid)) {
                licenseAddressIdByLicenseNetworkId.put(thisLicense.PJN_Veeva_Network_Id__c, networkRecord.licenseAddressVid);
            }

            updateLicenses.add(thisLicense);
        }

        for (PJN_NetworkRecord networkLicense : networkLicenses) {
            if (String.isBlank(networkLicense.vid) || licenseExtIds.contains(networkLicense.vid)) {
                continue;
            }

            String licenseStatus = networkLicense.getAttribute('license_status__v');

            if (String.isBlank(licenseStatus) || licenseStatus.toLowerCase() != 'a') {
                continue;
            }

            PJN_License__c thisLicense = new PJN_License__c (
                PJN_Veeva_Network_Id__c = networkLicense.vid
            );

            if (String.isNotBlank(networkLicense.entityType)) {
                PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getRecordTypeMappingByObjectAndNetworkRecordTypeName('PJN_License__c', networkLicense.entityType);

                if (networkRecordType != null) {
                    thisLicense.RecordTypeId = Schema.SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get(networkRecordType.PJN_Record_Type_Name__c).getRecordTypeId();
                }
            }

            if (String.isNotBlank(networkLicense.licenseAddressVid)) {
                licenseAddressIdByLicenseNetworkId.put(thisLicense.PJN_Veeva_Network_Id__c, networkLicense.licenseAddressVid);
            }

            thisLicense.put(networkLicenseSetting.PJN_Parent_Account_Field_Name__c, thisAccount.Id);

            thisLicense = (PJN_License__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisLicense, networkLicense, fieldMappings);
            updateLicenses.add(thisLicense);
        }

        Map<String, Id> licenseAddressIdByNetworkId = getLicenseAddressIdByNetworkId(licenseAddressIdByLicenseNetworkId);

        if (!licenseAddressIdByNetworkId.isEmpty()) {
            for (PJN_License__c updateLicense : updateLicenses) {
                String licenseAddressId = licenseAddressIdByLicenseNetworkId.get(updateLicense.PJN_Veeva_Network_Id__c);
                if (String.isNotBlank(licenseAddressId)) {
                    updateLicense.PJN_Contact_Information__c = licenseAddressIdByNetworkId.get(licenseAddressId);
                }
            }
        }

        return updateLicenses;
    }

    /**
     * Update affiliation from network or creating new licenses if need it
     * @param recordByNetworkId Map of network records by veeva network id
     */
    private List<PJN_Affiliation__c> buildOrUpdateAffiliations(Account thisAccount, List<PJN_NetworkRecord> networkAffiliations, Map<String, PJN_NetworkRecord> recordByNetworkId) {
        List<PJN_Affiliation__c> updateAffiliations = new List<PJN_Affiliation__c>();

        if (String.isBlank(networkAffilitionSetting.PJN_Sync_Record_Types_Allowed__c) || networkAffilitionSetting.PJN_Sync_Record_Types_Allowed__c.toLowerCase().contains('none')) {
            return updateAffiliations;
        }

        List<PJN_Network_Field_Mapping__mdt> fieldMappings = PJN_NetworkObjectSetting.getMappingsByName('PJN_Affiliation__c');

        Set<String> affiliationExtIds = new Set<String>();

        for (PJN_Affiliation__c thisAffiliation : thisAccount.Affiliation__r) {
            if (thisAffiliation.PJN_Veeva_Network_Id__c == null) {
                continue;
            }

            affiliationExtIds.add(thisAffiliation.PJN_Veeva_Network_Id__c);
            PJN_NetworkRecord networkRecord = recordByNetworkId.get(thisAffiliation.PJN_Veeva_Network_Id__c);

            String affiliationStatus = networkRecord.getAttribute('parent_hco_status__v');

            if (String.isBlank(affiliationStatus) || affiliationStatus.toLowerCase() != 'a') {
                continue;
            }

            thisAffiliation = (PJN_Affiliation__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisAffiliation, networkRecord, fieldMappings);

            updateAffiliations.add(thisAffiliation);
        }

        for (PJN_NetworkRecord networkAffiliation : networkAffiliations) {
            if (String.isBlank(networkAffiliation.vid) || affiliationExtIds.contains(networkAffiliation.vid)) {
                continue;
            }

            String affiliationStatus = networkAffiliation.getAttribute('parent_hco_status__v');

            if (String.isBlank(affiliationStatus) || affiliationStatus.toLowerCase() != 'a') {
                continue;
            }

            PJN_Affiliation__c thisAffiliation = new PJN_Affiliation__c (
                PJN_Veeva_Network_Id__c = networkAffiliation.vid
            );

            thisAffiliation.put(networkAffilitionSetting.PJN_Parent_Account_Field_Name__c, thisAccount.Id);

            thisAffiliation = (PJN_Affiliation__c) PJN_NetworkSyncUtility.updateRecordWithNetworkRecord(thisAffiliation, networkAffiliation, fieldMappings);
            updateAffiliations.add(thisAffiliation);
        }

        return updateAffiliations;
    }

    private Map<String, Id> getLicenseAddressIdByNetworkId(Map<String, String> licenseAddressIdByLicenseNetworkId) {
        Map<String, Id> licenseAddressIdByNetworkId = new Map<String, Id>();
        if (licenseAddressIdByLicenseNetworkId.isEmpty()) {
            return licenseAddressIdByNetworkId;
        }
        List<PJN_Contact_Information__c> licenseAddresses = [
            SELECT
                Id,
                PJN_Veeva_Network_Id__c
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Veeva_Network_Id__c IN :licenseAddressIdByLicenseNetworkId.values()
        ];
        for (PJN_Contact_Information__c licenseAddress : licenseAddresses) {
            licenseAddressIdByNetworkId.put(licenseAddress.PJN_Veeva_Network_Id__c, licenseAddress.Id);
        }
        return licenseAddressIdByNetworkId;
    }

    private void recalculateAffiliationsWithId() {
        if (updateAffiliations == null || updateAffiliations.isEmpty()) {
            return;
        }

        Map<String, Id> parentIdByExternalId = new Map<String, Id>();
        Map<Id, List<PJN_Affiliation__c>> affiliationsByChildAccountId = new Map<Id, List<PJN_Affiliation__c>>();

        for (PJN_Affiliation__c affiliation : updateAffiliations) {
            parentIdByExternalId.put(affiliation.PJN_Parent_Account__c, null);
            affiliationsByChildAccountId.put(String.valueOf(affiliation.get(networkAffilitionSetting.PJN_Parent_Account_Field_Name__c)), new List<PJN_Affiliation__c>());
        }

        List<Account> parentHCOs = [
            SELECT
                Id,
                PJN_Veeva_Network_Id__c
            FROM
                Account
            WHERE
                PJN_Veeva_Network_Id__c IN :parentIdByExternalId.keySet()
        ];

        for (Account parentHCO : parentHCOs) {
            parentIdByExternalId.put(parentHCO.PJN_Veeva_Network_Id__c, parentHCO.Id);
        }

        List<String> affiliationFields = new List<String> {
            'Id',
            'PJN_Parent_Account__c',
            'PJN_Veeva_Network_Id__c',
            networkAffilitionSetting.PJN_Parent_Account_Field_Name__c
        };

        Set<Id> childAccountIds = affiliationsByChildAccountId.keySet();

        String query = String.format (
            'SELECT {0} FROM PJN_Affiliation__c WHERE {1} IN :childAccountIds',
            new List<String> {
                String.join(affiliationFields, ','),
                networkAffilitionSetting.PJN_Parent_Account_Field_Name__c
            }
        );

        List<PJN_Affiliation__c> affiliations = (List<PJN_Affiliation__c>) Database.query(query);

        for (PJN_Affiliation__c affiliation : affiliations) {
            String childAccountId = String.valueOf(affiliation.get(networkAffilitionSetting.PJN_Parent_Account_Field_Name__c));
            List<PJN_Affiliation__c> currentAffiliations = affiliationsByChildAccountId.get(childAccountId);
            currentAffiliations.add(affiliation);
            affiliationsByChildAccountId.put(childAccountId, currentAffiliations);
        }

        List<PJN_Affiliation__c> affiliationsRecalculated = new List<PJN_Affiliation__c>();

        for (PJN_Affiliation__c affiliation : updateAffiliations) {
            Id parentHCOId = parentIdByExternalId.get(affiliation.PJN_Parent_Account__c);

            if (parentHCOId == null) {
                continue;
            }

            List<PJN_Affiliation__c> currentAffiliations = affiliationsByChildAccountId.get(String.valueOf(affiliation.get(networkAffilitionSetting.PJN_Parent_Account_Field_Name__c)));

            for (PJN_Affiliation__c currentAffiliation : currentAffiliations) {
                if (currentAffiliation.PJN_Parent_Account__c == parentHCOId) {
                    affiliation.Id = currentAffiliation.Id;
                    break;
                }
            }

            affiliation.PJN_Parent_Account__c = parentHCOId;
            affiliationsRecalculated.add(affiliation);
        }

        updateAffiliations = affiliationsRecalculated;
    }
}