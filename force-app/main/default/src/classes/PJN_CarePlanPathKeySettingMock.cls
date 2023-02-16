@isTest(isParallel=true) public with sharing class PJN_CarePlanPathKeySettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByCarePlanCoachSettingDeveloperName') {
            return this.queryByCarePlanCoachSettingDeveloperName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByCarePlanCoachSettingDeveloperName(String carePlanPathCoachingSettingDeveloperName) {
        return new PJN_CarePlan_Path_Keys_Setting__mdt(
            MasterLabel = 'Mocked Care Plan Path Key Setting',
            DeveloperName = 'PJN_Mocked_Care_Plan_Path_Key_Setting',
            PJN_CarePlan_Path_Coaching_Setting__r = new PJN_CarePlan_Path_Coaching_Setting__mdt(
                MasterLabel = 'Mocked Coaching',
                DeveloperName = carePlanPathCoachingSettingDeveloperName
            ),
            PJN_Fields__c = 'Subject,Status',
            PJN_Columns__c = 2
        );
    }
}