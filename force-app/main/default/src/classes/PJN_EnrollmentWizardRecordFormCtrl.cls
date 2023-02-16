/**
 * @author Mavens
 * @date Jan 2019
 * @description Get data from custom settings to build the form
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardRecordFormCtrl {
    /**
     * record form query
     */
    @TestVisible private static PJN_EnrollmentWizardRecordFormQuery enrollmentRecordFormQuery = new PJN_EnrollmentWizardRecordFormQuery();

    /**
     * record form fields query
     */
    @TestVisible private static PJN_EnrollmentFieldSetQuery enrollmentFieldSetQuery = new PJN_EnrollmentFieldSetQuery();

    /**
     * getEnrollmentWizardRecordForms retrieve enrollment form for a specific enrollment component id
     * @param  componentSettingId                       enrollment component id
     * @returns  PJN_Enrollment_Wizard_Record_Form__mdt  enrollment form metadata information
     */
    @auraEnabled public static Map<String, Object> getEnrollmentWizardRecordForms(Id componentSettingId) {
        try {
            PJN_Enrollment_Wizard_Record_Form__mdt recordFormSetting = enrollmentRecordFormQuery.getEnrollmentWizardRecordForm(componentSettingId);
            if(recordFormSetting.PJN_RecordType_DeveloperName__c != null) {
                setRecordTypeId(recordFormSetting);
            }
            List<PJN_Enrollment_Field_Set__mdt> enrollmentFields = enrollmentFieldSetQuery.queryByForm(recordFormSetting.Id);
            return new Map<String, Object> {
                'setting' => recordFormSetting,
                'fields' => enrollmentFields
            };
        } catch (Exception exc) {
            String msg = 'No form definition found. Please contact your system administrator.';
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
        }
    }

    @AuraEnabled
    public static Boolean getIsValidLookupId(String lookupId) {
        return (lookupId instanceOf Id);
    }

    /**
     * set record type id
     * @param  recordFormSetting custom metadata type record for enrollment wizard setting
     */
    private static void setRecordTypeId(PJN_Enrollment_Wizard_Record_Form__mdt recordFormSetting) {
        recordFormSetting.PJN_RecordType_DeveloperName__c = [
            SELECT
                Id
            FROM
                RecordType
            WHERE
                DeveloperName = :recordFormSetting.PJN_RecordType_DeveloperName__c
        ].Id;
    }
}