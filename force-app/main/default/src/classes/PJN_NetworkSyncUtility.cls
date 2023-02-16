/**
 * Network Sync Utility methods
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkSyncUtility {

    /**
     * Account record types allowed
     */
    public static String accountRecordTypesAllowed = PJN_NetworkObjectSetting.getSettingByName('Account').PJN_Sync_Record_Types_Allowed__c.toLowerCase();

    /**
     * Address record types allowed
     */
    public static String addressRecordTypesAllowed = PJN_NetworkObjectSetting.getSettingByName('PJN_Contact_Information__c').PJN_Sync_Record_Types_Allowed__c.toLowerCase();

    /**
     * License record types allowed
     */
    public static String licenseRecordTypesAllowed = PJN_NetworkObjectSetting.getSettingByName('PJN_License__c').PJN_Sync_Record_Types_Allowed__c.toLowerCase();

    /**
     * DCR Statuses to sync before account sync
     */
    private static final Set<String> DCR_STATUS_SYNC_BEFORE_ACCOUNT = new Set<String> {
        PJN_NetworkConstants.DCR_STATUS_PENDING,
        PJN_NetworkConstants.DCR_STATUS_SUBMITTED
    };

    /**
     * Query accounts and children
     * @param accountIds Account Ids
     * @returns `List<Account>`
     */
    public static List<Account> queryAccounts(Set<String> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return null;
        }

        return [
            SELECT
                Id,
                RecordType.DeveloperName,
                PJN_Veeva_Network_Id__c,
                PJN_Last_Date_Network_Synced__c,
                PJN_Last_Date_Network_Modified__c,
                LastModifiedDate,
                (
                    SELECT
                        Id,
                        RecordType.DeveloperName,
                        PJN_Veeva_Network_Id__c
                    FROM
                        PJN_Contact_Information__r
                ),
                (
                    SELECT
                        Id,
                        PJN_Veeva_Network_Id__c
                    FROM
                        PJN_Licenses__r
                ),
                (
                    SELECT
                        Id,
                        PJN_DCR_External_ID__c,
                        PJN_Status__c
                    FROM
                        PJN_Data_Change_Requests__r
                    WHERE
                        PJN_Status__c IN :DCR_STATUS_SYNC_BEFORE_ACCOUNT
                    AND
                        PJN_DCR_External_ID__c != null
                )
            FROM
                Account
            WHERE
                Id IN :accountIds
        ];
    }

    /**
     * Update Account Network Last modified date
     * @param thisAccount           Account record to be synced
     * @param accountNetworkRecord  Account Network record
     * @returns `Account`
     */
    public static Account updateLastModifiedDate(Account thisAccount, PJN_NetworkRecord accountNetworkRecord) {
        if (thisAccount == null || accountNetworkRecord == null) {
            return thisAccount;
        }

        String networkModifiedDate = String.valueOf(accountNetworkRecord.getAttribute('modified_date__v'));

        if (String.isNotBlank(networkModifiedDate)) {
            thisAccount.PJN_Last_Date_Network_Modified__c = (DateTime)JSON.deserialize('"' + networkModifiedDate + '"', DateTime.class);
        }

        return thisAccount;
    }

    /**
     * Checks if this account is allowed to be synced
     * @param thisAccount           Account record to be synced
     * @param networkAccountSetting Network Account settings
     * @returns `Boolean`
     */
    public static Boolean isAccountAllowedToSync(Account thisAccount, PJN_Network_Object_Setting__mdt networkAccountSetting) {
        // Account is synced when
        // Never synced before - PJN_Last_Date_Network_Synced__c == null
        // No modified date returned from Network - PJN_Last_Date_Network_Modified__c == null
        // Network modified data after synced - PJN_Last_Date_Network_Synced__c < PJN_Last_Date_Network_Modified__c
        // Network modified data after record - LastModifiedDate < PJN_Last_Date_Network_Modified__c
        Boolean allowedToSync = thisAccount.PJN_Last_Date_Network_Synced__c == null
            || thisAccount.PJN_Last_Date_Network_Modified__c == null
            || thisAccount.PJN_Last_Date_Network_Synced__c < thisAccount.PJN_Last_Date_Network_Modified__c
            || thisAccount.LastModifiedDate < thisAccount.PJN_Last_Date_Network_Modified__c;

        // Account not modified last sync delay minutes configured - PJN_Last_Date_Network_Synced__c < NOW - PJN_Sync_Delay__c minutes
        if (networkAccountSetting.PJN_Sync_Delay__c > 0) {
            Integer syncDelay = Integer.valueOf(networkAccountSetting.PJN_Sync_Delay__c);
            allowedToSync = allowedToSync || thisAccount.LastModifiedDate < System.now().addMinutes(-syncDelay);
        }

        return allowedToSync;
    }

    /**
     * Get Entity Value mapped using PJN_Network_Value_Mapping__mdt
     * @param valueMappings PJN_Network_Value_Mapping__mdt records
     * @param entityValue   Entity value responded by Network
     * @returns `Object`
     */
    public static Object getEntityValueMapped(List<PJN_Network_Value_Mapping__mdt> valueMappings, Object entityValue) {
        if (valueMappings == null) {
            return entityValue;
        }

        for (PJN_Network_Value_Mapping__mdt valueMapping : valueMappings) {
            if (valueMapping.PJN_Inbound__c && valueMapping.PJN_External_Value__c == String.valueOf(entityValue)) {
                entityValue = valueMapping.PJN_Value__c;
                break;
            }
        }

        return entityValue;
    }

    public static Map<String, Map<String, PJN_Data_Change_Request__c>> getDCRsByExtIdFromNetworkResponse(List<PJN_NetworkEntity> networkChangeRequests) {
        Map<String, Map<String, PJN_Data_Change_Request__c>> dcrsByExtId = new Map<String, Map<String, PJN_Data_Change_Request__c>>();

        if (networkChangeRequests == null || networkChangeRequests.isEmpty()) {
            return dcrsByExtId;
        }

        Set<String> networkChangeRequestIds = new Set<String>();

        for (PJN_NetworkEntity networkChangeRequest : networkChangeRequests) {
            if (String.isBlank(networkChangeRequest.changeRequestId)) {
                continue;
            }

            networkChangeRequestIds.add(networkChangeRequest.changeRequestId);
        }

        for (PJN_Data_Change_Request__c dcr : PJN_DCRQuery.queryWithLinesByNetworkIds(networkChangeRequestIds)) {
            String dcrExternalId = dcr.PJN_Parent_Data_Change_Request__c != null ?
                dcr.PJN_Parent_Data_Change_Request__r.PJN_DCR_External_Id__c :
                dcr.PJN_DCR_External_Id__c;

            Map<String, PJN_Data_Change_Request__c> dcrByRecordId = dcrsByExtId.containsKey(dcrExternalId) ?
                dcrsByExtId.get(dcrExternalId) :
                new Map<String, PJN_Data_Change_Request__c>();

            String recordExtId = String.isNotBlank(dcr.PJN_Veeva_Network_Id__c) ?
                dcr.PJN_Veeva_Network_Id__c :
                dcr.PJN_External_Id__c.substringBeforeLast('|');

            dcrByRecordId.put(recordExtId, dcr);

            dcrsByExtId.put(dcrExternalId, dcrByRecordId);
        }

        return dcrsByExtId;
    }

    /**
     * Get map of network records by veeva network id
     * @param entities  List of entities from Network response
     * @returns `Map<String, Map<String, PJN_NetworkRecord>>`
     */
    public static Map<String, Map<String, PJN_NetworkRecord>> getRecordByNetworkIdsByExtId(List<PJN_NetworkEntity> networkEntities) {
        Map<String, Map<String, PJN_NetworkRecord>> entityByNetworkIdByExtId = new Map<String, Map<String, PJN_NetworkRecord>>();

        if (networkEntities == null || networkEntities.isEmpty()) {
            return entityByNetworkIdByExtId;
        }

        for (PJN_NetworkEntity networkEntity : networkEntities) {
            Map<String, PJN_NetworkRecord> entityByNetworkId = new Map<String, PJN_NetworkRecord>();

            entityByNetworkId.put(networkEntity.entity.vid, networkEntity.entity);

            entityByNetworkId.putAll(getChildNetworkRecord(networkEntity.entity.addresses));
            entityByNetworkId.putAll(getChildNetworkRecord(networkEntity.entity.licenses));

            entityByNetworkIdByExtId.put(networkEntity.entity.vid, entityByNetworkId);
        }

        return entityByNetworkIdByExtId;
    }

    /**
     * Get map of network children records by netowkr id
     * @param networkChildrenRecords    Children Network records to be mapped
     * @returns `Map<String, PJN_NetworkRecord>`
     */
    private static Map<String, PJN_NetworkRecord> getChildNetworkRecord(List<PJN_NetworkRecord> networkChildrenRecords) {
        Map<String, PJN_NetworkRecord> childByNetworkId = new Map<String, PJN_NetworkRecord>();

        for (PJN_NetworkRecord networkChildRecord : networkChildrenRecords) {
            childByNetworkId.put(networkChildRecord.vid, networkChildRecord);
        }

        return childByNetworkId;
    }

    /**
     * Update SFDC Record with Network Record
     * @param thisRecord    SFDC Record
     * @param networkRecord Network Record
     * @param fieldMappings Record field Mappings
     * @returns `SObject`
     */
    public static SObject updateRecordWithNetworkRecord(SObject thisRecord, PJN_NetworkRecord networkRecord, List<PJN_Network_Field_Mapping__mdt> fieldMappings) {
        for (PJN_Network_Field_Mapping__mdt fieldMapping : fieldMappings) {
            if (!fieldMapping.PJN_Sync_Transmission__c) {
                continue;
            }

            Object entityValue = networkRecord.getAttribute(fieldMapping.PJN_External_Field_Name__c);
            entityValue = PJN_NetworkSyncUtility.getEntityValueMapped(fieldMapping.PJN_Network_Value_Mappings__r, entityValue);

            thisRecord.put(fieldMapping.PJN_Field_API_Name__c, getFieldValueWithFieldType(thisRecord.getSObjectType().getDescribe().getName(), fieldMapping.PJN_Field_API_Name__c, String.valueOf(entityValue)));
        }

        return thisRecord;
    }

    private static Object getFieldValueWithFieldType(String sobjectName, String fieldName, String fieldValue) {
        if (String.isBlank(sobjectName) || String.isBlank(fieldName) || String.isBlank(fieldValue)) {
            return fieldValue;
        }
        Object fieldValueObject = fieldValue;

        Schema.DisplayType fieldType = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
        if(fieldType == Schema.DisplayType.DATE) {
            fieldValueObject = Date.valueOf(fieldValue);
        } else if(fieldType == Schema.DisplayType.DATETIME) {
            fieldValueObject = Datetime.valueOf(fieldValue);
        } else if (fieldType == Schema.DisplayType.BOOLEAN) {
            fieldValueObject = Boolean.valueOf(fieldValue);
        }

        return fieldValueObject;
    }
}