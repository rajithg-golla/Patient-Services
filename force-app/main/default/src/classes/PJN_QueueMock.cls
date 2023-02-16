/**
 * @author      Mavens
 * @group       MappingEngine
 * @description queue mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_QueueMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByDeveloperName') {
            return this.queryByDeveloperName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByDeveloperName(String developerName) {
        if(developerName == 'PJN_DOES_NOT_EXIST') {
            throw new System.QueryException('TEST');
        } else {
            Group queue = new Group(
                Name = 'Mocked Group',
                DeveloperName = developerName
            );
            insert queue;
            return queue;
        }
    }
}