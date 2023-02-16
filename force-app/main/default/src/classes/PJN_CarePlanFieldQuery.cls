/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to query care plan field metadata
 */
public with sharing class PJN_CarePlanFieldQuery {
    /**
     * query by care plan path coaching setting developer name
     * @param   String        carePlanPathCoachingSettingDeveloperName
     * @returns  List<PJN_Care_Plan_Field__mdt>
     */
    public List<PJN_Care_Plan_Field__mdt> queryByCoachingSettingDeveloperName(String carePlanPathCoachingSettingDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Field_API_Name__c,
                PJN_Field_Label__c,
                PJN_Icon_Name__c,
                PJN_Icon_Size__c,
                PJN_Order__c
            FROM
                PJN_Care_Plan_Field__mdt
            WHERE
                PJN_CarePlan_Path_Coaching_Setting__r.DeveloperName = :carePlanPathCoachingSettingDeveloperName
            ORDER BY
                PJN_Order__c ASC
        ];
    }

    /**
     * query by care plan program developer name
     * @param   String        carePlanProgramDeveloperName
     * @returns  List<PJN_Care_Plan_Field__mdt>
     */
    public List<PJN_Care_Plan_Field__mdt> queryByCarePlanProgramDeveloperName(String carePlanProgramDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Field_API_Name__c,
                PJN_Field_Label__c,
                PJN_Icon_Name__c,
                PJN_Icon_Size__c,
                PJN_Order__c
            FROM
                PJN_Care_Plan_Field__mdt
            WHERE
                PJN_Program__r.DeveloperName = :carePlanProgramDeveloperName
            AND
                PJN_CarePlan_Path_Coaching_Setting__c = null
            ORDER BY
                PJN_Order__c ASC
        ];
    }
}