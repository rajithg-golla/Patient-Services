/**
 * @author      Mavens
 * @group       MDM
 * @description Query for MDM Connection metadata
 */
public with sharing class MVN_MDMConnectionQuery {

    /**
     * Retrieve all Active MDM Connection metadatas
     * @return  `List<MVN_MDM_Connection__mdt>`
     */
    public List<MVN_MDM_Connection__mdt> queryAll() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                MVN_Named_Credential__c,
                MVN_Environment__c
            FROM
                MVN_MDM_Connection__mdt
            WHERE
                MVN_Is_Active__c = true
        ];
    }
}