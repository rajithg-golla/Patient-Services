@isTest(isParallel=true) public with sharing class PJN_CarePlanFieldMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByCoachingSettingDeveloperName') {
            return this.queryByCoachingSettingDeveloperName((String) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryByCarePlanProgramDeveloperName') {
            return this.queryByCarePlanProgramDeveloperName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByCoachingSettingDeveloperName(String carePlanPathCoachingSettingDeveloperName) {
        List<PJN_Care_Plan_Field__mdt> carePlanFields = new List<PJN_Care_Plan_Field__mdt>();
        carePlanFields.add(
            new PJN_Care_Plan_Field__mdt(
                MasterLabel = 'Mocked Care Plan Field',
                DeveloperName = 'PJN_Mocked_Care_Plan_Field',
                PJN_CarePlan_Path_Coaching_Setting__r = new PJN_CarePlan_Path_Coaching_Setting__mdt(
                    MasterLabel = 'Mocked Coaching',
                    DeveloperName = carePlanPathCoachingSettingDeveloperName
                ),
                PJN_Field_API_Name__c = 'PJN_TestComponent',
                PJN_Field_Label__c = 'A',
                PJN_Icon_Name__c = 'standard:default',
                PJN_Icon_Size__c = 'small',
                PJN_Order__c = 1
            )
        );
        return carePlanFields;
    }

    private Object queryByCarePlanProgramDeveloperName(String carePlanProgramDeveloperName) {
        List<PJN_Care_Plan_Field__mdt> carePlanFields = new List<PJN_Care_Plan_Field__mdt>();
        carePlanFields.add(
            new PJN_Care_Plan_Field__mdt(
                MasterLabel = 'Mocked Care Plan Field',
                DeveloperName = 'PJN_Mocked_Care_Plan_Field',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Coaching',
                    DeveloperName = carePlanProgramDeveloperName
                ),
                PJN_Field_API_Name__c = 'PJN_TestComponent',
                PJN_Field_Label__c = 'A',
                PJN_Icon_Name__c = 'standard:default',
                PJN_Icon_Size__c = 'small',
                PJN_Order__c = 1
            )
        );
        return carePlanFields;
    }


}