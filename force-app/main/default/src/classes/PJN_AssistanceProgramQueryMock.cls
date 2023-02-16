/**
 * @author      Mavens
 * @date        11/2020
 * @description Mock response for PJN_AssistanceProgramQuery
 * @group       CoverageInvestigation
 */
@isTest
public with sharing class PJN_AssistanceProgramQueryMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'activeByCarePlanId') {
            return this.activeByCarePlanId((Set<String>)listOfArgs[0], (Set<Id>)listOfArgs[1]);
        } else {
            return null;
        }
    }

    private List<PJN_Assistance_Program__c> activeByCarePlanId(Set<String> fields, Set<Id> carePlanIds) {
        List<PJN_Assistance_Program__c> assistancePrograms = new List<PJN_Assistance_Program__c>();
        for (Id carePlanId : carePlanIds) {
            assistancePrograms.add(new PJN_Assistance_Program__c(PJN_Care_Plan__c=carePlanId));
            assistancePrograms.add(new PJN_Assistance_Program__c(PJN_Care_Plan__c=carePlanId));
        }
        return assistancePrograms;
    }
}