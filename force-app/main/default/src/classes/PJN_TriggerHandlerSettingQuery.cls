/**
 * @author      Mavens
 * @group       PJN_TriggerDispatcher
 * @description class to query trigger handler settings
 */
public with sharing class PJN_TriggerHandlerSettingQuery {
    /**
     * trigger handler settings map by sObject type
     */
    @TestVisible
    private static Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>>();

    /**
     * query trigger handler setting by sObject type
     * @param   SObjectType         thisSObjectType
     * @returns  List<PJN_Trigger_Handler_Setting__mdt>
     */
    public List<PJN_Trigger_Handler_Setting__mdt> queryBySObjectType(SObjectType thisSObjectType) {
        if(!triggerHandlerSettingBySObjectType.containsKey(thisSObjectType)) {
            triggerHandlerSettingBySObjectType.put(
                thisSObjectType,
                [
                    SELECT
                        Id,
                        DeveloperName,
                        PJN_Class__c,
                        PJN_Event__c,
                        PJN_Order__c
                    FROM
                        PJN_Trigger_Handler_Setting__mdt
                    WHERE
                        PJN_SObject_API_Name__c = :thisSObjectType.getDescribe().getName()
                    AND
                        PJN_Active__c = true
                    ORDER BY
                        PJN_Order__c ASC
                ]
            );
        }
        return triggerHandlerSettingBySObjectType.get(thisSObjectType);
    }
}