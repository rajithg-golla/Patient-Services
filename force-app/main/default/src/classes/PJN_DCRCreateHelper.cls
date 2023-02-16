/**
 * Helper creating DCRs
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRCreateHelper {

    /**
     * Gets accounts related to the records in a map by account id
     * @returns `Map<Id, Account>`
     */
    public static Map<Id, Account> getAccountsRelatedMap(List<SObject> records) {
        Set<Id> accountIds = new Set<Id>();

        for (SObject thisRecord : records) {
            if (thisRecord.get('PJN_Account__c') == null) {
                continue;
            }

            accountIds.add(String.valueOf(thisRecord.get('PJN_Account__c')));
        }

        Set<String> fieldNames = new Set<String> {
            'Id',
            'RecordType.DeveloperName',
            'PJN_Veeva_Network_Id__c'
        };

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : PJN_NetworkObjectSetting.getMappingsByName(Account.sObjectType.getDescribe().getName())) {
            if (!networkFieldMapping.PJN_Required_for_DCR_Transmission__c) {
                continue;
            }

            fieldNames.add(networkFieldMapping.PJN_Field_API_Name__c);
        }

        List<String> fieldNameList = new List<String>();
        fieldNameList.addAll(fieldNames);

        String query = 'SELECT ' +
            String.join(fieldNameList, ',') + ' ' +
            'FROM ' + Account.sObjectType.getDescribe().getName() + ' ' +
            'WHERE Id IN :accountIds';

        return new Map<Id, Account> ((List<Account>) Database.query(String.escapeSingleQuotes(query)));
    }

    /**
     * Upsert DCR Lines when those are created during DCR Create process
     * @param dcrLines  Data change request lines to be insert or updated
     */
    public static void upsertDCRLines(List<PJN_Data_Change_Request_Line__c> dcrLines) {
        Set<String> dcrExternalIds = new Set<String>();
        Set<String> fieldNames = new Set<String>();

        for (PJN_Data_Change_Request_Line__c dcrLine : dcrLines) {
            dcrExternalIds.add(dcrLine.PJN_Data_Change_Request__r.PJN_External_Id__c);
            fieldNames.add(dcrLine.PJN_Field_API_Name__c);
        }

        Map<String, PJN_Data_Change_Request_Line__c> existingDCRLineByKey = new Map<String, PJN_Data_Change_Request_Line__c>();

        for (PJN_Data_Change_Request_Line__c existingDCRLine : PJN_DCRQuery.queryDCRLinesWithFieldName(dcrExternalIds, fieldNames)) {
            existingDCRLineByKey.put(getDCRLineKey(existingDCRLine), existingDCRLine);
        }

        Map<String, PJN_Data_Change_Request_Line__c> upsertDcrLinesByKey = new Map<String, PJN_Data_Change_Request_Line__c>();

        for (PJN_Data_Change_Request_Line__c dcrLine : dcrLines) {
            String mapKey = getDCRLineKey(dcrLine);

            if (!existingDCRLineByKey.containsKey(mapKey)) {
                upsertDcrLinesByKey.put(mapKey, dcrLine);
                continue;
            }

            PJN_Data_Change_Request_Line__c existingDcrLine = existingDCRLineByKey.get(mapKey);
            existingDcrLine.PJN_New_Value__c = dcrLine.PJN_New_Value__c;
            upsertDcrLinesByKey.put(mapKey, existingDcrLine);
        }

        upsert upsertDcrLinesByKey.values();
    }

    /**
     * Get DCR Line key map to identify DCR Lines for same DCR and field name
     * @param dcrLine   Data change request line to get the key
     * @returns `String`
     */
    private static String getDCRLineKey(PJN_Data_Change_Request_Line__c dcrLine) {
        return dcrLine.PJN_Data_Change_Request__r.PJN_External_Id__c + '|' + dcrLine.PJN_Field_API_Name__c;
    }



    /**
     * Handles DCRs with error to update them to Cancelled
     * @param dcrs                  List of DCRs
     * @param errorMessageByDCRId   Map of error messages by DCR id
     */
    public static void updateDCRsWithError(List<PJN_Data_Change_Request__c> dcrs, Map<Id, String> errorMessageByDCRId) {
        if (errorMessageByDCRId == null || errorMessageByDCRId.isEmpty()) {
            return;
        }

        List<PJN_Data_Change_Request__c> updateDCRs = new List<PJN_Data_Change_Request__c>();

        for(PJN_Data_Change_Request__c dcr : dcrs) {
            Id dcrId = dcr.PJN_Parent_Data_Change_Request__c != null ?
                dcr.PJN_Parent_Data_Change_Request__c :
                dcr.Id;

            if (!errorMessageByDCRId.containsKey(dcrId)) {
                continue;
            }

            dcr.PJN_Error__c = errorMessageByDCRId.get(dcrId);
            dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_CANCELLED;
            dcr.PJN_Sent_Datetime__c = System.now();

            updateDCRs.add(dcr);
        }

        if (updateDCRs != null && !updateDCRs.isEmpty()) {
            update updateDCRs;
        }
    }

    /**
     * Send List of parent object filters and check if allowed to create DCRs
     * @param networkParentFilters  List of Network Object Parent Filters
     * @param parentAccount         Parent account record
     * @returns `Boolean`
     */
    public static Boolean isParentObjectFilterAllowed(List<PJN_Network_Parent_Object_Filter__mdt> networkParentFilters, Account parentAccount) {
        Boolean noParentFilter = networkParentFilters != null && networkParentFilters.isEmpty();

        if (noParentFilter) {
            return false;
        }

        if (networkParentFilters != null) {
            for (PJN_Network_Parent_Object_Filter__mdt networkParentFilter : networkParentFilters) {
                if (!networkParentFilter.PJN_DCR__c) {
                    continue;
                }

                String parentFilter = networkParentFilter.PJN_Parent_Field__c.contains('.') ?
                    String.valueOf(parentAccount.getSObject(networkParentFilter.PJN_Parent_Field__c.substringBefore('.')).get(networkParentFilter.PJN_Parent_Field__c.substringAfter('.'))) :
                    String.valueOf(parentAccount.get(networkParentFilter.PJN_Parent_Field__c));

                Boolean noMatchFilter = parentFilter != networkParentFilter.PJN_Parent_Field_Value__c;

                if (noMatchFilter) {
                    return false;
                }
            }
        }

        return true;
    }
}