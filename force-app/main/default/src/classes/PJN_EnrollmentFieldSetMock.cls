/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for Enrollment Field Set custom metadata
* @group EnrollmentWizard
*/
@isTest(isParallel=true) public with sharing class PJN_EnrollmentFieldSetMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'queryByForm'){
            return this.queryByForm((Id) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByForm(Id enrollmentRecordFormId) {
        return new List<PJN_Enrollment_Field_Set__mdt> {
            new PJN_Enrollment_Field_Set__mdt(
                MasterLabel = 'Enrollment Field Set Mock',
                DeveloperName = 'PJN_Enrollment_Field_Set_Mock',
                PJN_Field_API_Name__c = 'Name',
                PJN_Is_Required__c = false,
                PJN_Order__c = 10
            )
        };
    }
}