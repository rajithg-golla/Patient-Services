@isTest(isParallel=true) public with sharing class PJN_AllCarePlanFieldSettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryBySettingDeveloperNames') {
            return this.queryBySettingDeveloperNames((Set<String>) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryBySettingDeveloperNames(Set<String> allCarePlanSettingDeveloperNamesSet) {
        List<PJN_All_Care_Plan_Setting_Field__mdt> allCarePlanFieldSettings = new List<PJN_All_Care_Plan_Setting_Field__mdt>();
        for(String allCarePlanSettingDeveloperName : allCarePlanSettingDeveloperNamesSet) {
            allCarePlanFieldSettings.add(
                new PJN_All_Care_Plan_Setting_Field__mdt(
                    MasterLabel = 'Mocked All Care Plan Setting 1',
                    DeveloperName = 'PJN_Mocked_ALL_Care_Plan_Field_Setting_1',
                    PJN_All_Care_Plan_Setting__r = new PJN_All_Care_Plan_Setting__mdt(
                        MasterLabel = 'Mocked All Care Plan Setting',
                        DeveloperName = allCarePlanSettingDeveloperName
                    ),
                    PJN_Field_Label__c = 'Case Number',
                    PJN_Field_API_Name__c = 'CaseNumber',
                    PJN_Link_Record_Id_Field_API_Name__c = 'Id',
                    PJN_Order__c = 10
                )
            );
            allCarePlanFieldSettings.add(
                new PJN_All_Care_Plan_Setting_Field__mdt(
                    MasterLabel = 'Mocked All Care Plan Setting 2',
                    DeveloperName = 'PJN_Mocked_ALL_Care_Plan_Field_Setting_2',
                    PJN_All_Care_Plan_Setting__r = new PJN_All_Care_Plan_Setting__mdt(
                        MasterLabel = 'Mocked All Care Plan Setting',
                        DeveloperName = allCarePlanSettingDeveloperName
                    ),
                    PJN_Field_Label__c = 'Subject',
                    PJN_Field_API_Name__c = 'Subject',
                    PJN_Link_Record_Id_Field_API_Name__c = null,
                    PJN_Order__c = 20
                )
            );
        }
        return allCarePlanFieldSettings;
    }
}