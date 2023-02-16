/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get care plan path key field setting
 */
public with sharing class PJN_CarePlanPathKeysCtrl {
    /**
     * care plan field query
     */
    @testVisible private static PJN_CarePlanPathKeySettingQuery carePlanPathKeySettingQuery = new PJN_CarePlanPathKeySettingQuery();

    /**
     * get care plan path key field setting for this coaching setting
     * @param   String        carePlanPathCoachingSettingDeveloperName
     * @returns  PJN_CarePlan_Path_Keys_Setting__mdt
     */
    @auraEnabled public static PJN_CarePlan_Path_Keys_Setting__mdt getCarePlanPathKeyFieldsSetting(String carePlanPathCoachingSettingDeveloperName) {
        try {
            return carePlanPathKeySettingQuery.queryByCarePlanCoachSettingDeveloperName(carePlanPathCoachingSettingDeveloperName);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}