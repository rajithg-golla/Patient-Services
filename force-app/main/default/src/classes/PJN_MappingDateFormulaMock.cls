/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping Date Formula mock provider
 */
@isTest(isParallel=false) public with sharing class PJN_MappingDateFormulaMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByMapping') {
            return this.queryByMapping((PJN_Mapping__mdt) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByMapping(PJN_Mapping__mdt mapping) {
        if(mapping.DeveloperName == 'PJN_DOES_NOT_EXIST') {
            throw new System.QueryException('TEST');
        } else {
            return new List<PJN_Mapping_Date_Formula__mdt> {
                new PJN_Mapping_Date_Formula__mdt(
                    MasterLabel = 'Mocked Mapping Date Formula NOW',
                    DeveloperName = 'PJN_Mocked_Mapping_Date_Formula_NOW',
                    PJN_Target_Field_API_Name__c = 'HealthCloudGA__SourceSystemModified__c',
                    PJN_Formula__c = 'NOW',
                    PJN_Days_To_Add__c = 0,
                    PJN_Mapping__r = mapping
                ),
                new PJN_Mapping_Date_Formula__mdt(
                    MasterLabel = 'Mocked Mapping Date Formula TODAY',
                    DeveloperName = 'PJN_Mocked_Mapping_Date_Formula_TODAY',
                    PJN_Target_Field_API_Name__c = 'PJN_Override_Next_Activity__c',
                    PJN_Formula__c = 'TODAY',
                    PJN_Days_To_Add__c = 1,
                    PJN_Mapping__r = mapping
                ),
                new PJN_Mapping_Date_Formula__mdt(
                    MasterLabel = 'Mocked Mapping Date Formula FIELD',
                    DeveloperName = 'PJN_Mocked_Mapping_Date_Formula_FIELD',
                    PJN_Source_Field_API_Name__c = 'HealthCloudGA__DueDate__c',
                    PJN_Target_Field_API_Name__c = 'HealthCloudGA__DueDate__c',
                    PJN_Formula__c = 'FIELD',
                    PJN_Days_To_Add__c = -1,
                    PJN_Mapping__r = mapping
                )
            };
        }
    }
}