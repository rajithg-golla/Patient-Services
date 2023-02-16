/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query all care plan field settings
 */
public with sharing class PJN_AllCarePlanFieldSettingQuery {
    /**
     * query all
     * @param   Set<String>         allCarePlanSettingDeveloperNamesSet
     * @returns  List<PJN_All_Care_Plan_Setting_Field__mdt>
     */
    public List<PJN_All_Care_Plan_Setting_Field__mdt> queryBySettingDeveloperNames(Set<String> allCarePlanSettingDeveloperNamesSet) {
        return [
            SELECT
                PJN_Field_Label__c,
                PJN_Field_API_Name__c,
                PJN_Link_Record_Id_Field_API_Name__c,
                PJN_All_Care_Plan_Setting__r.DeveloperName,
                PJN_Order__c
            FROM
                PJN_All_Care_Plan_Setting_Field__mdt
            WHERE
                PJN_All_Care_Plan_Setting__r.DeveloperName IN :allCarePlanSettingDeveloperNamesSet
            ORDER BY
                PJN_Order__c NULLS LAST
        ];
    }
}