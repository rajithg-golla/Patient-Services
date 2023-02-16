@isTest(isParallel=true) public with sharing class PJN_CarePlanTimelineCaseMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if(stubbedMethodName == 'queryByProgramAndActivityType') {
            return this.queryByProgramAndActivityType((String) listOfArgs[0], (String) listOfArgs[1]);
        } else {
            return null;
        }
    }

    private Object queryByProgramAndActivityType(String programDeveloperName, String activityType) {
        return new PJN_Care_Plan_Timeline_Case__mdt(
            MasterLabel = 'Mocked Timeline',
                DeveloperName = 'PJN_Mocked_Timeline',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = programDeveloperName
                ),
                PJN_Activity_Type__c = activityType,
                PJN_Icon_Name__c = 'standard:default'
        );
    }
}