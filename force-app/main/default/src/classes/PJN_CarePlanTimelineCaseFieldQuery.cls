/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query care plan timeline case fields
 */
public with sharing class PJN_CarePlanTimelineCaseFieldQuery {
    /**
     * query by care plan program
     * @param   String        carePlanProgramDeveloperName
     * @returns  List<PJN_Care_Plan_Timeline_Case_Field__mdt>
     */
    public List<PJN_Care_Plan_Timeline_Case_Field__mdt> queryByCarePlanProgram(String carePlanProgramDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Field_API_Name__c
            FROM
                PJN_Care_Plan_Timeline_Case_Field__mdt
            WHERE
                PJN_Care_Plan_Timeline_Case__r.PJN_Program__r.DeveloperName = :carePlanProgramDeveloperName
            AND
                PJN_Care_Plan_Timeline_Case__r.PJN_Activity_Type__c != 'planned'
        ];
    }

    /**
     * query by care plan program and activity type
     * @param   String        carePlanProgramDeveloperName
     * @param   String        activityType
     * @returns  List<PJN_Care_Plan_Timeline_Case_Field__mdt>
     */
    public List<PJN_Care_Plan_Timeline_Case_Field__mdt> queryByCarePlanTimelineCase(String carePlanTimelineCaseDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Order__c,
                PJN_Field_Label__c,
                PJN_Field_API_Name__c,
                PJN_Care_Plan_Timeline_Case__r.PJN_Icon_Name__c
            FROM
                PJN_Care_Plan_Timeline_Case_Field__mdt
            WHERE
                PJN_Care_Plan_Timeline_Case__r.DeveloperName = :carePlanTimelineCaseDeveloperName
            ORDER BY
                PJN_Order__c ASC
        ];
    }
}