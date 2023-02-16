/**
 * @author      Mavens
 * @group       MDM
 * @description Query for MDM Field and Value Mapping metadatas
 */
public with sharing class MVN_MDMFieldMappingQuery {

    /**
     * Retrieve all Active MDM Field and Value Mapping metadatas
     * @return  `List<MVN_MDM_Field_Mapping__mdt>`
     */
    public List<MVN_MDM_Field_Mapping__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                MVN_Inbound__c,
                MVN_Is_Lookup_Field__c,
                MVN_Lookup_Field_Filter__c,
                MVN_Lookup_sObject__c,
                MVN_MDM_Field__c,
                MVN_MDM_Object_Setting__c,
                MVN_Outbound__c,
                MVN_SFDC_Field__c,
                (
                    SELECT
                        Id,
                        DeveloperName,
                        MasterLabel,
                        MVN_Inbound__c,
                        MVN_MDM_Value__c,
                        MVN_SFDC_Value__c,
                        MVN_Outbound__c
                    FROM
                        MVN_MDM_Value_Mappings__r
                    WHERE
                        MVN_Is_Active__c = true
                )
            FROM
                MVN_MDM_Field_Mapping__mdt
            WHERE
                MVN_Is_Active__c = true
        ];
    }
}