/**
 * @author      Mavens
 * @date        10/2020
 * @description Stub for accessing Assistance Program Eligibility Configurations
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_AssistProgEligibilityConfigQueryMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'getConfigurationByDevName') {
            return this.getConfigurationByDevName((String) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private PJN_Assistance_Prog_Eligibility_Config__mdt getConfigurationByDevName(String devName) {
        return new PJN_Assistance_Prog_Eligibility_Config__mdt(
            PJN_Clearing_House_Class__c = 'PJN_ExperianHealthAPI'
        );
    }
}