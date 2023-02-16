/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping queue mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingQueueMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByMapping') {
            return this.queryByMapping((PJN_Mapping__mdt) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByMapping(PJN_Mapping__mdt mapping) {
        if(mapping.DeveloperName == 'PJN_DOES_NOT_EXIST') {
            throw new System.QueryException('TEST');
        } else {
            return new PJN_Mapping_Queue__mdt(
                MasterLabel = 'Mocked Mapping Record Type',
                DeveloperName = 'PJN_Mocked_Mapping_record_Type',
                PJN_Queue_API_Name__c = 'PJN_Test_Queue',
                PJN_Target_Field_API_Name__c = 'OwnerId',
                PJN_Mapping__r = mapping
            );
        }
    }
}