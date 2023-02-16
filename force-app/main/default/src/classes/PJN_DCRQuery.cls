/**
 * DCR query wrapper to obtain Data change requests and lines related
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRQuery {

    /**
     * Get Data change requests and lines using ids
     * @param dcrIds    Data change request ids
     * @returns `List<PJN_Data_Change_Request__c>`
     */
    public static List<PJN_Data_Change_Request__c> queryWithLinesByIds(Set<Id> dcrIds) {
        return [
            SELECT
                Id,
                Name,
                RecordTypeId,
                PJN_Status__c,
                PJN_Account__c,
                PJN_Account__r.RecordTypeId,
                PJN_Account__r.RecordType.DeveloperName,
                PJN_Contact_Information__c,
                PJN_Contact_Information__r.RecordTypeId,
                PJN_Contact_Information__r.RecordType.DeveloperName,
                PJN_DCR_External_Id__c,
                PJN_License__c,
                PJN_License__r.PJN_Type__c,
                PJN_License_Address__c,
                PJN_License_Address_Network_Id__c,
                PJN_Veeva_Network_Id__c,
                PJN_External_Id__c,
                PJN_Parent_Data_Change_Request__c,
                PJN_Type__c,
                PJN_Record_Type_Name__c,
                PJN_Record_External_Id__c,
                RecordType.DeveloperName,
                CreatedDate,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c,
                        PJN_Final_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
            WHERE
                Id IN :dcrIds
            ORDER BY
                PJN_Sent_Datetime__c DESC
        ];
    }

    /**
     * Get Data change requests and lines using network ids
     * @param networkDCRIds Network Data change request ids
     * @returns `List<PJN_Data_Change_Request__c>`
     */
    public static List<PJN_Data_Change_Request__c> queryWithLinesByNetworkIds(Set<String> networkDCRIds) {
        return [
            SELECT
                Id,
                Name,
                RecordTypeId,
                PJN_Status__c,
                PJN_Account__c,
                PJN_Account__r.RecordTypeId,
                PJN_Account__r.RecordType.DeveloperName,
                PJN_Contact_Information__c,
                PJN_Contact_Information__r.RecordTypeId,
                PJN_Contact_Information__r.RecordType.DeveloperName,
                PJN_DCR_External_Id__c,
                PJN_License__c,
                PJN_License_Address__c,
                PJN_License_Address_Network_Id__c,
                PJN_License__r.PJN_Type__c,
                PJN_Veeva_Network_Id__c,
                PJN_External_Id__c,
                PJN_Parent_Data_Change_Request__c,
                PJN_Parent_Data_Change_Request__r.PJN_DCR_External_Id__c,
                PJN_Type__c,
                PJN_Record_Type_Name__c,
                PJN_Record_External_Id__c,
                RecordType.DeveloperName,
                CreatedDate,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c,
                        PJN_Final_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
            WHERE
                PJN_DCR_External_Id__c IN :networkDCRIds
            OR
                PJN_Parent_Data_Change_Request__r.PJN_DCR_External_Id__c IN :networkDCRIds
            ORDER BY
                PJN_Sent_Datetime__c DESC
        ];
    }

    /**
     * Get Data change requests and lines using dcrs
     * @param dcrs  Data change requests
     * @returns `List<PJN_Data_Change_Request__c>`
     */
    public static List<PJN_Data_Change_Request__c> queryWithLinesByDCRs(List<PJN_Data_Change_request__c> dcrs) {
        return [
            SELECT
                Id,
                Name,
                RecordTypeId,
                PJN_Status__c,
                PJN_Account__c,
                PJN_Account__r.RecordTypeId,
                PJN_Account__r.RecordType.DeveloperName,
                PJN_Contact_Information__c,
                PJN_Contact_Information__r.RecordTypeId,
                PJN_Contact_Information__r.RecordType.DeveloperName,
                PJN_DCR_External_Id__c,
                PJN_License__c,
                PJN_License__r.PJN_Type__c,
                PJN_License_Address__c,
                PJN_License_Address_Network_Id__c,
                PJN_Veeva_Network_Id__c,
                PJN_External_Id__c,
                PJN_Parent_Data_Change_Request__c,
                PJN_Type__c,
                PJN_Record_Type_Name__c,
                PJN_Record_External_Id__c,
                RecordType.DeveloperName,
                CreatedDate,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c,
                        PJN_Final_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
            WHERE
                Id IN :dcrs
            ORDER BY
                PJN_Sent_Datetime__c DESC
        ];
    }

    public static List<PJN_Data_Change_Request__c> getPendingWithLinesByParentDCRs(List<PJN_Data_Change_Request__c> parentDCRs) {
        return [
            SELECT
                Id,
                Name,
                RecordTypeId,
                PJN_Status__c,
                PJN_Account__c,
                PJN_Account__r.RecordTypeId,
                PJN_Account__r.RecordType.DeveloperName,
                PJN_Contact_Information__c,
                PJN_Contact_Information__r.RecordTypeId,
                PJN_Contact_Information__r.RecordType.DeveloperName,
                PJN_DCR_External_Id__c,
                PJN_License__c,
                PJN_License__r.PJN_Type__c,
                PJN_License_Address__c,
                PJN_License_Address_Network_Id__c,
                PJN_Veeva_Network_Id__c,
                PJN_External_Id__c,
                PJN_Parent_Data_Change_Request__c,
                PJN_Type__c,
                PJN_Record_Type_Name__c,
                PJN_Record_External_Id__c,
                RecordType.DeveloperName,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c,
                        PJN_Final_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
            WHERE
                PJN_Parent_Data_Change_Request__c IN :parentDCRs
            AND
                PJN_Status__c = :PJN_NetworkConstants.DCR_STATUS_PENDING
            ORDER BY
                PJN_Sent_Datetime__c DESC
        ];
    }

    /**
     * Get Data change request lines using external dcr ids and field names
     * @param dcrExternalIds    Data change request External Ids
     * @param fieldNames        List of field names
     * @returns `List<PJN_Data_Change_Request_Line__c>`
     */
    public static List<PJN_Data_Change_Request_Line__c> queryDCRLinesWithFieldName(Set<String> dcrExternalIds, Set<String> fieldNames) {
        return [
            SELECT
                Id,
                Name,
                PJN_Account__c,
                PJN_Field_Label__c,
                PJN_Field_API_Name__c,
                PJN_Old_Value__c,
                PJN_New_Value__c,
                PJN_Data_Change_Request__r.PJN_External_Id__c
            FROM
                PJN_Data_Change_Request_Line__c
            WHERE
                PJN_Data_Change_Request__r.PJN_External_Id__c IN :dcrExternalIds
            AND
                PJN_Field_API_Name__c IN :fieldNames
        ];
    }
}