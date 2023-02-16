/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query care plan path coach settings
 */
public with sharing class PJN_CarePlanPathCoachingSettingQuery {
    /**
     * query by program problem developer name
     * @param   String        programProblemDeveloperName
     * @returns  List<PJN_CarePlan_Path_Coaching_Setting__mdt>
     */
    public List<PJN_CarePlan_Path_Coaching_Setting__mdt> queryByProgramProblemDeveloperName(String programProblemDeveloperName) {
        return [
            SELECT
                Id,
                DeveloperName,
                PJN_Component_Name__c,
                PJN_Mode__c
            FROM
                PJN_CarePlan_Path_Coaching_Setting__mdt
            WHERE
                PJN_Program_Problem__r.DeveloperName = :programProblemDeveloperName
            ORDER BY
                PJN_Mode__c ASC
        ];
    }
}