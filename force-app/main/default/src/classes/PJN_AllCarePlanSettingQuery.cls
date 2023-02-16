/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query all care plan settings
 */
public with sharing class PJN_AllCarePlanSettingQuery {
    /**
     * query all
     * @returns  List<PJN_All_Care_Plan_Setting__mdt>
     */
    public List<PJN_All_Care_Plan_Setting__mdt> queryAll() {
        return [
            SELECT
                DeveloperName,
                PJN_Program__r.DeveloperName,
                PJN_Title_Field_API_Name__c,
                PJN_Subtitle_Field_API_Name__c,
                PJN_Is_Path_Expandable__c
            FROM
                PJN_All_Care_Plan_Setting__mdt
        ];
    }
}