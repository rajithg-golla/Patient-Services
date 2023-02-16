/**
 * @author Mavens
 * @date Mar 2019
 * @description Class to query custom metadata types for PJN_Enrollment_Field_Set__mdt
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentFieldSetQuery {
    /**
     * query enrollment form fields
     * @param   recordFormSettingId   enrollment wizard record form id
     * @returns  List<PJN_Enrollment_Field_Set__mdt>
     */
    public List<PJN_Enrollment_Field_Set__mdt> queryByForm(Id recordFormSettingId) {
        return [
            SELECT
                Id,
                PJN_Field_API_Name__c,
                PJN_Is_Required__c,
                PJN_Order__c
            FROM
                PJN_Enrollment_Field_Set__mdt
            WHERE
                PJN_Enrollment_Wizard_Record_Form__c = :recordFormSettingId
            ORDER BY
                PJN_Order__c
        ];
    }
}