/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Wizard_Record_Form__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardRecordFormQuery {
    /**
     * Query enrollment wizard record form by enrollment wizard component id
     * @param   componentSettingId   enrollment wizard component id
     * @returns                       PJN_Enrollment_Wizard_Record_Form__mdt
     */
    public PJN_Enrollment_Wizard_Record_Form__mdt getEnrollmentWizardRecordForm(Id componentSettingId) {
        return [
            SELECT
                Id,
                Label,
                DeveloperName,
                PJN_SObject_API_Name__c,
                PJN_RecordType_DeveloperName__c,
                PJN_Care_Plan_Lookup_Field_API_Name__c,
                PJN_Edit_Care_Plan_Record_Form__c
            FROM
                PJN_Enrollment_Wizard_Record_Form__mdt
            WHERE
                PJN_Enrollment_Wizard_Component__c = :componentSettingId
            LIMIT 1
        ];
    }
}