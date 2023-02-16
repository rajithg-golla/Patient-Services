/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryMappingsByJobName') {
            return this.queryMappingsByJobName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryMappingsByJobName(String jobName) {
        return new List<PJN_Mapping__mdt> {
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = jobName == 'PJN_Care_Team_Mapping' ? 'zipToTeam' : 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Always_Runs__c = false,
                PJN_Mapping_Type__c = 'PJN_Field',
                PJN_Mapping_Job__r = new PJN_Mapping_Job__mdt(
                    MasterLabel = 'Mocked Mapping',
                    DeveloperName = jobName,
                    PJN_Target_Object_API_Name__c = 'Case',
                    PJN_Is_Active__c = true
                )
            )
        };
    }
}