/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query care plan timeline case
 */
public with sharing class PJN_CarePlanTimelineCaseQuery {
    /**
     * query by care plan program
     * @param   String        programDeveloperName
     * @param   String        activityType
     * @returns  PJN_Care_Plan_Timeline_Case__mdt
     */
    public PJN_Care_Plan_Timeline_Case__mdt queryByProgramAndActivityType(String programDeveloperName, String activityType) {
        return [
            SELECT
                Id,
                DeveloperName,
                PJN_Icon_Name__c
            FROM
                PJN_Care_Plan_Timeline_Case__mdt
            WHERE
                PJN_Program__r.DeveloperName = :programDeveloperName
            AND
                PJN_Activity_Type__c = :activityType
            LIMIT
                1
        ];
    }
}