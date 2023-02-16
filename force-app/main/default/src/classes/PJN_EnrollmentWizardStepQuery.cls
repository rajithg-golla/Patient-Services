/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Wizard_Step__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardStepQuery {

    /**
     * Query enrollment wizard steps bry program
     * @param  programDevName   program developer name
     * @returns                  List<PJN_Enrollment_Wizard_Step__mdt>
     */
    public List<PJN_Enrollment_Wizard_Step__mdt> getEnrollmentStepsByProgram(String programDevName) {
        PJN_EnrollmentWizardSettingQuery enrollmentSettingQuery = new PJN_EnrollmentWizardSettingQuery();
        return [
            SELECT
                Id,
                Label,
                PJN_Order__c
            FROM
                PJN_Enrollment_Wizard_Step__mdt
            WHERE
                PJN_Enrollment_Wizard_Setting__c = :enrollmentSettingQuery.getAllSettingsByProgram().get(programDevName).Id
            ORDER BY
                PJN_Order__c ASC
        ];
    }
}