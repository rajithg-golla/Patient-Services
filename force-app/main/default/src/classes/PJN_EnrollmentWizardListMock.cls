/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for Enrollment Wizard Record List custom metadata
* @group Mock
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentWizardListMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'getEnrollmentWizardRecordList'){
            return this.getEnrollmentWizardRecordList((Id) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object getEnrollmentWizardRecordList(Id componentSettingId) {
        if (componentSettingId == null) {
            String msg = 'No list definition found. Please contact your system administrator.';
            throw new PJN_EnrollmentWizardException(msg);
        }
        return new PJN_Enrollment_Wizard_Record_List__mdt(
            MasterLabel = 'Prescription List Setting',
            DeveloperName = 'PJN_Prescription_List_Setting',
            PJN_Fields__c = 'HealthCloudGA__DispenseMedicationCode__c',
            PJN_Editable__c = true,
            PJN_Deletable__c = true,
            PJN_SObject_API_Name__c = 'HealthCloudGA__EhrMedicationPrescription__c',
            PJN_Care_Plan_Lookup_Field_API_Name__c = 'PJN_Care_Plan__c',
            PJN_Where_Clause__c = ' HealthCloudGA__DispenseMedicationCode__c != null ',
            PJN_Order_By__c = ' HealthCloudGA__DispenseMedicationCode__c '
        );
    }
}