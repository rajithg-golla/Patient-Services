/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for Enrollment Wizard Step custom metadata
* @group Mock
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentWizardStepMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'getEnrollmentStepsByProgram'){
            return this.getEnrollmentStepsByProgram((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object getEnrollmentStepsByProgram(String programDevName) {
        if (programDevName == null) {
            String msg = 'No enrollment settings found. Please contact your administrator';
            throw new PJN_EnrollmentWizardException(msg);
        }
        PJN_Enrollment_Wizard_Setting__mdt setting = new PJN_Enrollment_Wizard_Setting__mdt(
            MasterLabel = 'Cholecap Enrollment Setting',
            PJN_Program_DeveloperName__c = 'PJN_CLP'
        );

        List<PJN_Enrollment_Wizard_Step__mdt> stepList = new List<PJN_Enrollment_Wizard_Step__mdt>();
        stepList.add(
            new PJN_Enrollment_Wizard_Step__mdt(
                MasterLabel = 'Case Step',
                DeveloperName = 'PJN_Case_Step',
                PJN_Enrollment_Wizard_Setting__c = setting.Id,
                PJN_Order__c = 10
            )
        );
        stepList.add(
            new PJN_Enrollment_Wizard_Step__mdt(
                MasterLabel = 'Prescription Step',
                DeveloperName = 'PJN_Prescription_Step',
                PJN_Enrollment_Wizard_Setting__c = setting.Id,
                PJN_Order__c = 20
            )
        );
        return stepList;
    }
}