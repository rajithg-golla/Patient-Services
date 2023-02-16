/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Wizard_Setting__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardSettingQuery {

    /**
     * Query enrollment wizard settings and return a map of settings by program
     * @returns   Map<String, PJN_Enrollment_Wizard_Setting__mdt>
     */
    public Map<String, PJN_Enrollment_Wizard_Setting__mdt> getAllSettingsByProgram() {
        Map<String, PJN_Enrollment_Wizard_Setting__mdt> allSettingsByProgram = new Map<String, PJN_Enrollment_Wizard_Setting__mdt>();
        for (PJN_Enrollment_Wizard_Setting__mdt setting : getAllSettings()) {
            allSettingsByProgram.put(setting.PJN_Program_DeveloperName__c, setting);
        }
        return allSettingsByProgram;
    }

    /**
     * Query all enrollment wizard settings
     * @returns   List<PJN_Enrollment_Wizard_Setting__mdt>
     */
    private List<PJN_Enrollment_Wizard_Setting__mdt> getAllSettings() {
        return [
            SELECT
                Id,
                PJN_Program_DeveloperName__c
            FROM
                PJN_Enrollment_Wizard_Setting__mdt
        ];
    }

}