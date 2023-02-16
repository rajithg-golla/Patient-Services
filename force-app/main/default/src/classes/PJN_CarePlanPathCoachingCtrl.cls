/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get all care plan path coaching settings to enable dynamically loading the UI components
 */
public with sharing class PJN_CarePlanPathCoachingCtrl {
    /**
     * care plan path coach setting query
     */
    @testVisible private static PJN_CarePlanPathCoachingSettingQuery carePlanPathCoachingSettingQuery = new PJN_CarePlanPathCoachingSettingQuery();

    /**
     * get all coach settings to fill out the care plan ui
     * @param   String        programProblemDeveloperName
     */
    @auraEnabled public static List<PJN_CarePlan_Path_Coaching_Setting__mdt> getCarePlanPathCoachingSettingsComponent(String programProblemDeveloperName) {
        try {
            return carePlanPathCoachingSettingQuery.queryByProgramProblemDeveloperName(programProblemDeveloperName);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}