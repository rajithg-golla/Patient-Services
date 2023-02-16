/**
 * Query PJN_Network_Field_Mapping__mdt custom metadatas
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkFieldMappingsQuery {

    /**
     * Query all active Network Field mappings including Network Value Mappings related
     * @returns `List<PJN_Network_Field_Mapping__mdt>`
     */
    public List<PJN_Network_Field_Mapping__mdt> queryAllWithValues() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Network_Object__c,
                PJN_Network_Object__r.PJN_SObject_Name__c,
                PJN_External_Field_Name__c,
                PJN_Field_API_Name__c,
                PJN_Required_for_DCR_Transmission__c,
                PJN_DCR_Update_After_Approval__c,
                PJN_SObject_Record_Type__c,
                PJN_DCR_Transmission__c,
                PJN_Sync_Transmission__c,
                (
                    SELECT
                        Id,
                        DeveloperName,
                        MasterLabel,
                        PJN_Network_Field_Mapping__c,
                        PJN_External_Value__c,
                        PJN_Inbound__c,
                        PJN_Outbound__c,
                        PJN_Value__c
                    FROM
                        PJN_Network_Value_Mappings__r
                )
            FROM
                PJN_Network_Field_Mapping__mdt
            WHERE
                PJN_Active__c = true
        ];
    }
}