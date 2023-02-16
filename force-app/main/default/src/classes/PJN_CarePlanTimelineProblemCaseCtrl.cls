/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get care plan timeline problem cases settings
 */
public with sharing class PJN_CarePlanTimelineProblemCaseCtrl {
    /**
     * care plan timeline case field query
     */
    @testVisible private static PJN_CarePlanTimelineCaseQuery carePlanTimelineCaseQuery = new PJN_CarePlanTimelineCaseQuery();

    /**
     * care plan timeline case field query
     */
    @testVisible private static PJN_CarePlanTimelineCaseFieldQuery carePlanTimelineCaseFieldQuery = new PJN_CarePlanTimelineCaseFieldQuery();

    /**
     * get care plan timeline problem cases settings
     * @param   String        programDeveloperName
     * @param   String        activityType
     * @returns  List<PJN_Care_Plan_Timeline_Case_Field__mdt>
     */
    @auraEnabled public static Map<String, Object> getActivitySettings(String programDeveloperName, String activityType) {
        try {
            PJN_Care_Plan_Timeline_Case__mdt activitySetting = carePlanTimelineCaseQuery.queryByProgramAndActivityType(programDeveloperName, activityType);
            return new Map<String, Object> {
                'activitySetting' => activitySetting,
                'activityFieldSettings' => carePlanTimelineCaseFieldQuery.queryByCarePlanTimelineCase(activitySetting.DeveloperName)
            };
        } catch(Exception ex) {
            throw new AuraHandledException('Something went wrong. Please contact your system administrator.');
        }
    }
}