/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for Enrollment Wizard Record Formm custom metadata
* @group EnrollmentWizard
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentWizardFormMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'getEnrollmentWizardRecordForm'){
            return this.getEnrollmentWizardRecordForm((Id) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object getEnrollmentWizardRecordForm(Id componentSettingId) {
        if (componentSettingId == null) {
            String msg = 'No form definition found. Please contact your system administrator.';
            throw new PJN_EnrollmentWizardException(msg);
        }
        return new PJN_Enrollment_Wizard_Record_Form__mdt(
            MasterLabel = 'Case Form Setting',
            DeveloperName = 'PJN_Case_Form_Setting',
            PJN_SObject_API_Name__c = 'Case',
            PJN_RecordType_DeveloperName__c = 'CarePlan'
        );
    }
}