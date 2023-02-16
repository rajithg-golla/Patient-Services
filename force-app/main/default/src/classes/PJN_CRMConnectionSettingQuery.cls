/**
 * @author      Mavens
 * @description class to query CRM Connection Settings
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PJN_CRMConnectionSettingQuery {
    /**
     * query all
     * @param String PJN_Type to filter by.
     * @returns List<PJN_CRM_Connection_Setting__mdt>
     */
    public List<PJN_CRM_Connection_Setting__mdt> queryBySettingByType(String type) {
        System.debug('Querying PJN_CRM_Connection_Setting__mdt');
        return [SELECT PJN_Active__c,
                       PJN_CRM_Connection_Class__c,
                       PJN_Named_Credential__c,
                       PJN_Trigger_Field__c,
                       PJN_Case_Sync_Dismissed_Status__c,
                       PJN_Case_Sync_Complete_Status__c
                  FROM PJN_CRM_Connection_Setting__mdt
                 WHERE PJN_Type__c = :type
                   AND PJN_Active__c = TRUE];
    }
}