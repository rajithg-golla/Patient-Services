/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping Field mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingFieldMock implements System.StubProvider {
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
            return new List<PJN_Mapping_Field__mdt> {
                new PJN_Mapping_Field__mdt(
                    MasterLabel = 'Mocked Mapping Field',
                    DeveloperName = 'PJN_Mocked_Mapping_Field',
                    PJN_Source_Field_API_Name__c = 'Parent.Name',
                    PJN_Target_Field_API_Name__c = 'Name',
                    PJN_Mapping__r = mapping
                ),
                new PJN_Mapping_Field__mdt(
                    MasterLabel = 'Mocked Mapping Field Boolean',
                    DeveloperName = 'PJN_Mocked_Mapping_Field_Boolean',
                    PJN_Source_Field_API_Name__c = 'HealthCloudGA__Disabled__c',
                    PJN_Target_Field_API_Name__c = 'HealthCloudGA__Disabled__c',
                    PJN_Mapping__r = mapping
                )
            };
        }
    }
}