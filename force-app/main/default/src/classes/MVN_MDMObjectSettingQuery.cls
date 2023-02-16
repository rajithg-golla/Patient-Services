/**
 * @author      Mavens
 * @group       MDM
 * @description Query for MDM Object Settings metadata
 */
public with sharing class MVN_MDMObjectSettingQuery {

    /**
     * Retrieve all Active MDM Object Setting metadatas
     * @return  `List<MVN_MDM_Object_Setting__mdt>`
     */
    public List<MVN_MDM_Object_Setting__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                MVN_MDM_Connection__c,
                MVN_SObject_API_Name__c,
                MVN_MDM_Object_Name__c
            FROM
                MVN_MDM_Object_Setting__mdt
            WHERE
                MVN_Is_Active__c = true
        ];
    }
}