/**
 * Query PJN_Network_Record_Type_Mapping__mdt custom metadatas
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkRecordTypeMappingsQuery {

    /**
     * Query all Network Record Type Mappings
     * @returns `List<PJN_Network_Record_Type_Mapping__mdt>`
     */
    public List<PJN_Network_Record_Type_Mapping__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Network_Object_Setting__c,
                PJN_Network_Object_Setting__r.PJN_SObject_Name__c,
                PJN_Network_Record_Type__c,
                PJN_Network_Record_SubType__c,
                PJN_Record_Type_Name__c,
                PJN_Inbound__c,
                PJN_Outbound__c
            FROM
                PJN_Network_Record_Type_Mapping__mdt
        ];
    }
}