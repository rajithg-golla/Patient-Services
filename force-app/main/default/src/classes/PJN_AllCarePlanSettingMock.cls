@isTest(isParallel=true) public with sharing class PJN_AllCarePlanSettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryAll') {
            return this.queryAll();
        } else {
            return null;
        }
    }

    private Object queryAll() {
        List<PJN_All_Care_Plan_Setting__mdt> allCarePlanSettings = new List<PJN_All_Care_Plan_Setting__mdt>();
        allCarePlanSettings.add(
            new PJN_All_Care_Plan_Setting__mdt(
                MasterLabel = 'Mocked All Care Plan Setting',
                DeveloperName = 'PJN_Mocked_ALL_Care_Plan_Setting',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = 'PJN_Mocked_Program'
                ),
                PJN_Title_Field_API_Name__c = 'Subject',
                PJN_Subtitle_Field_API_Name__c = 'CaseNumber',
                PJN_Is_Path_Expandable__c = true
            )
        );
        return allCarePlanSettings;
    }
}