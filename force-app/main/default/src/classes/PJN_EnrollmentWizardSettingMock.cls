/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for PJN_EnrollmentWizardSetting class
* @group EnrollmentWizard
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentWizardSettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'getAllSettingsByProgram'){
            return this.getAllSettingsByProgram();
        } else {
            return null;
        }
    }

    private Object getAllSettingsByProgram() {
        PJN_Enrollment_Wizard_Setting__mdt setting = new PJN_Enrollment_Wizard_Setting__mdt(
            MasterLabel = 'Cholecap Enrollment Setting',
            PJN_Program_DeveloperName__c = 'CLP_TEST'
        );
        return new Map<String, PJN_Enrollment_Wizard_Setting__mdt>{
            'CLP_TEST' => setting
        };
    }
}