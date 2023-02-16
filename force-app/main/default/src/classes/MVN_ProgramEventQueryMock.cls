/**
* @author Mavens
* @description Mocks for Program Event Query
* @group Events
*/
public with sharing class MVN_ProgramEventQueryMock implements System.StubProvider{

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'forProblems') {
            return new Map<String, List<MVN_Program_Event__mdt>> {
                'PJN_RLN_Missing_Info_Stage' => new List<MVN_Program_Event__mdt>{
                    new MVN_Program_Event__mdt(
                        MVN_Program_Developer_Name__c = 'PJN_RLN_Missing_Info_Stage',
                        MVN_Record_Status__c = 'Open',
                        MVN_SObject__c = 'HealthCloudGA__CarePlanProblem__c',
                        MVN_Therapy_Status__c = 'Pending',
                        MVN_Therapy_Sub_Status__c = 'Program Initiation In Progress'
                    )
                }
            };
        }

        if (stubbedMethodName == 'forActivities') {
            return new Map<String, List<MVN_Program_Event__mdt>> {
                '' => new List<MVN_Program_Event__mdt>{}
            };
        }

        if (stubbedMethodName == 'forFulfillmentRequests') {
            return new Map<String, List<MVN_Program_Event__mdt>> {
                '' => new List<MVN_Program_Event__mdt>{}
            };
        }

        return null;
    }
}