/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get all care plan field settings for this coaching setting
 */
public with sharing class PJN_CarePlanPathGuidanceCtrl {
    /**
     * care plan field query
     */
    @testVisible private static PJN_CarePlanFieldQuery carePlanFieldQuery = new PJN_CarePlanFieldQuery();

    /**
     * get all care plan field settings for this coaching setting
     * @param   String        carePlanPathCoachingSettingDeveloperName
     * @returns  List<PJN_Care_Plan_Field__mdt>
     */
    @auraEnabled public static List<PJN_Care_Plan_Field__mdt> getCarePlanFields(String carePlanPathCoachingSettingDeveloperName) {
        try {
            return carePlanFieldQuery.queryByCoachingSettingDeveloperName(carePlanPathCoachingSettingDeveloperName);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}