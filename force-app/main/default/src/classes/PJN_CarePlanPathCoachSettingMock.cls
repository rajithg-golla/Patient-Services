@isTest(isParallel=true) public with sharing class PJN_CarePlanPathCoachSettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByProgramProblemDeveloperName') {
            return this.queryByProgramProblemDeveloperName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByProgramProblemDeveloperName(String programProblemDeveloperName) {
        List<PJN_CarePlan_Path_Coaching_Setting__mdt> carePlanPathCoachingSettings = new List<PJN_CarePlan_Path_Coaching_Setting__mdt>();
        carePlanPathCoachingSettings.add(
            new PJN_CarePlan_Path_Coaching_Setting__mdt(
                MasterLabel = 'Mocked Care Plan Path Coaching Setting',
                DeveloperName = 'PJN_Mocked_Care_Plan_Path_Coaching_Setting',
                PJN_Program_Problem__r = new PJN_Program_Problem__mdt(
                    MasterLabel = 'Mocked Program Problem',
                    DeveloperName = programProblemDeveloperName
                ),
                PJN_Component_Name__c = 'PJN_TestComponent',
                PJN_Mode__c = 'A'
            )
        );
        return carePlanPathCoachingSettings;
    }
}