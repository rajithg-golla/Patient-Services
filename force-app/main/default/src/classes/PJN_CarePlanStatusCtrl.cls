/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get all care plan field settings for this care plan
 */
public with sharing class PJN_CarePlanStatusCtrl {
    /**
     * care plan field query
     */
    @testVisible private static PJN_CarePlanFieldQuery carePlanFieldQuery = new PJN_CarePlanFieldQuery();

    /**
     * get all care plan field settings for this care plan
     * @param   String        carePlanPathCoachingSettingDeveloperName
     * @returns  List<PJN_Care_Plan_Field__mdt>
     */
    @auraEnabled public static List<PJN_Care_Plan_Field__mdt> getCarePlanFields(String carePlanProgramDeveloperName) {
        return carePlanFieldQuery.queryByCarePlanProgramDeveloperName(carePlanProgramDeveloperName);
    }
}