@isTest(isParallel=true) public with sharing class PJN_CarePlanTimelineCaseFieldMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if(stubbedMethodName == 'queryByCarePlanProgram') {
            return this.queryByCarePlanProgram((String) listOfArgs[0]);
        } else if(stubbedMethodName == 'queryByCarePlanTimelineCase') {
            return this.queryByCarePlanTimelineCase((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByCarePlanProgram(String carePlanProgramDeveloperName) {
        return new List<PJN_Care_Plan_Timeline_Case_Field__mdt> {
            new PJN_Care_Plan_Timeline_Case_Field__mdt(
                MasterLabel = 'Mocked Care Plan Timeline Case Field',
                DeveloperName = 'PJN_Mocked_Care_Plan_Timeline_Case_Field',
                PJN_Care_Plan_Timeline_Case__r = new PJN_Care_Plan_Timeline_Case__mdt(
                    MasterLabel = 'Mocked Timeline',
                    DeveloperName = 'PJN_Mocked_Timeline',
                    PJN_Program__r = new PJN_Program__mdt(
                        MasterLabel = 'Mocked Program',
                        DeveloperName = carePlanProgramDeveloperName
                    ),
                    PJN_Activity_Type__c = 'open',
                    PJN_Icon_Name__c = 'standard:default'
                ),
                PJN_Field_API_Name__c = 'Subject'
            )
        };
    }

    private Object queryByCarePlanTimelineCase(String carePlanTimelineCaseDeveloperName) {
        return new List<PJN_Care_Plan_Timeline_Case_Field__mdt> {
            new PJN_Care_Plan_Timeline_Case_Field__mdt(
                MasterLabel = 'Mocked Care Plan Timeline Case Field',
                DeveloperName = 'PJN_Mocked_Care_Plan_Timeline_Case_Field',
                PJN_Care_Plan_Timeline_Case__r = new PJN_Care_Plan_Timeline_Case__mdt(
                    MasterLabel = 'Mocked Timeline',
                    DeveloperName = carePlanTimelineCaseDeveloperName
                ),
                PJN_Field_API_Name__c = 'Subject'
            )
        };
    }
}