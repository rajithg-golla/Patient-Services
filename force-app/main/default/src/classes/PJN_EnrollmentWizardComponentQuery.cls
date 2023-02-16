/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Wizard_Component__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardComponentQuery {

    /**
     * Query enrollment wizard components by enrollment wizard step id
     * @param   stepId   enrollment wizard step id
     * @returns           List<PJN_Enrollment_Wizard_Component__mdt>
     */
    public List<PJN_Enrollment_Wizard_Component__mdt> getEnrollmentComponentsByStep(Id stepId) {
        return [
            SELECT
                Id,
                Label,
                PJN_Order__c,
                PJN_Component_To_Load__c,
                PJN_Section_Title__c
            FROM
                PJN_Enrollment_Wizard_Component__mdt
            WHERE
                PJN_Enrollment_Wizard_Step__c = :stepId
            ORDER BY
                PJN_Order__c ASC
        ];
    }
}