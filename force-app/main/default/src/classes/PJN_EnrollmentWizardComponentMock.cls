/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for Enrollment Wizard Component custom metadata
* @group Mock
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentWizardComponentMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'getEnrollmentComponentsByStep'){
            return this.getEnrollmentComponentsByStep((Id) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object getEnrollmentComponentsByStep(Id stepId) {
        if (stepId == null) {
            String msg = 'No enrollment settings found. Please contact your administrator';
            throw new PJN_EnrollmentWizardException(msg);
        }
        List<PJN_Enrollment_Wizard_Component__mdt> componentList = new List<PJN_Enrollment_Wizard_Component__mdt>();
        componentList.add(
            new PJN_Enrollment_Wizard_Component__mdt(
                MasterLabel = 'Case Form Component',
                DeveloperName = 'PJN_Case_Form_Component',
                PJN_Order__c = 10,
                PJN_Component_To_Load__c = 'PJN_EnrollmenWizardRecordForm',
                PJN_Section_Title__c = 'Case'
            )
        );
        componentList.add(
            new PJN_Enrollment_Wizard_Component__mdt(
                MasterLabel = 'Case List Component',
                DeveloperName = 'PJN_Case_List_Component',
                PJN_Order__c = 20,
                PJN_Component_To_Load__c = 'PJN_EnrollmentWizardRecordList',
                PJN_Section_Title__c = 'Existing Case'
            )
        );
        return componentList;
    }
}