/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query care plan path key setting
 */
public with sharing class PJN_CarePlanPathKeySettingQuery {
    /**
     * query by care plan coaching setting
     * @param   String        carePlanPathCoachingSettingDeveloperName
     * @returns  PJN_CarePlan_Path_Keys_Setting__mdt
     */
    public PJN_CarePlan_Path_Keys_Setting__mdt queryByCarePlanCoachSettingDeveloperName(String carePlanPathCoachingSettingDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Fields__c,
                PJN_Columns__c
            FROM
                PJN_CarePlan_Path_Keys_Setting__mdt
            WHERE
                PJN_CarePlan_Path_Coaching_Setting__r.DeveloperName = :carePlanPathCoachingSettingDeveloperName
            LIMIT
                1
        ];
    }
}