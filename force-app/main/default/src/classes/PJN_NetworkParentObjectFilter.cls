/**
 * Query PJN_Network_Parent_Object_Filter__mdt custom metadatas
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkParentObjectFilter {

    /**
     * Query all Network Parent Object Filters
     * @returns `List<PJN_Network_Parent_Object_Filter__mdt>`
     */
    public List<PJN_Network_Parent_Object_Filter__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Network_Object_Setting__c,
                PJN_Network_Object_Setting__r.PJN_SObject_Name__c,
                PJN_Object_Record_Type__c,
                PJN_Parent_Field__c,
                PJN_Parent_Field_Value__c,
                PJN_DCR__c,
                PJN_Sync__c
            FROM
                PJN_Network_Parent_Object_Filter__mdt
        ];
    }
}