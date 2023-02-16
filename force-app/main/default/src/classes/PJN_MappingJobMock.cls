/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping job mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingJobMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByJobName') {
            return this.queryByJobName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByJobName(String jobName) {
        return new PJN_Mapping_Job__mdt(
            MasterLabel = 'Mocked Mapping Job',
            DeveloperName = jobName,
            PJN_Target_Object_API_Name__c = 'Case',
            PJN_Is_Active__c = true
        );
    }
}