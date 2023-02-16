/**
 * Query PJN_Object_Field_Contact_Info_Mapping__mdt custom metadatas
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_ObjectFieldContactInfoMappingsQuery {
    /**
     * Query all Object Field Contact Info mappings
     * @returns `List<PJN_Object_Field_Contact_Info_Mapping__mdt>`
     */
    public List<PJN_Object_Field_Contact_Info_Mapping__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Contact_Info_Field_Name__c,
                PJN_Contact_Info_Record_Type__c,
                PJN_Contact_Info_Type__c,
                PJN_Field_Name__c,
                PJN_Object_Name__c
            FROM
                PJN_Object_Field_Contact_Info_Mapping__mdt
        ];
    }
}