@isTest(isParallel=true) public with sharing class PJN_FulfillmentRequestCreateMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if(stubbedMethodName == 'queryByProgramDeveloperNameAndRecordTypeDeveloperName') {
            return this.queryByProgramDeveloperNameAndRecordTypeDeveloperName((String) listOfArgs[0], (String) listOfArgs[1]);
        } else {
            return null;
        }
    }

    private Object queryByProgramDeveloperNameAndRecordTypeDeveloperName(String programDeveloperName, String recordTypeDeveloperName) {
        if(programDeveloperName == 'PJN_NO_MAPPING') {
            return new List<PJN_Fulfillment_Request_Creation__mdt>();
        } else {
            return new List<PJN_Fulfillment_Request_Creation__mdt> {
                new PJN_Fulfillment_Request_Creation__mdt(
                    MasterLabel = 'Mocked Fulfillment Request Creation',
                    DeveloperName = 'PJN_Mocked_Fulfillment_Request_Creation',
                    PJN_Program__r = new PJN_Program__mdt(
                        MasterLabel = 'Mocked Program',
                        DeveloperName = programDeveloperName
                    ),
                    PJN_Care_Plan_Source_Field_API_Name__c = 'Id',
                    PJN_Request_Target_Field_API_Name__c = 'PJN_Care_Plan__c',
                    PJN_Record_Type_Developer_Name__c = recordTypeDeveloperName
                )
            };
        }
    }
}