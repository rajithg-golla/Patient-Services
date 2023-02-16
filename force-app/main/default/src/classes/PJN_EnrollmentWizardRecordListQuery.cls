/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Wizard_Record_List__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardRecordListQuery {
    /**
     * Query enrollment wizard record list by enrollment wizard component id
     * @param   componentSettingId   enrollment wizard component id
     * @returns                       PJN_Enrollment_Wizard_Record_List__mdt
     */
    public PJN_Enrollment_Wizard_Record_List__mdt getEnrollmentWizardRecordList(Id componentSettingId) {
        return [
            SELECT
                Id,
                Label,
                DeveloperName,
                PJN_SObject_API_Name__c,
                PJN_Fields__c,
                PJN_Where_Clause__c,
                PJN_Order_By__c,
                PJN_RecordType_DeveloperName__c,
                PJN_Editable__c,
                PJN_Deletable__c,
                PJN_Care_Plan_Lookup_Field_API_Name__c
            FROM
                PJN_Enrollment_Wizard_Record_List__mdt
            WHERE
                PJN_Enrollment_Wizard_Component__c = :componentSettingId
            LIMIT 1
        ];
    }
}