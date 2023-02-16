/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping label mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingLabelMock implements System.StubProvider {
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
            return new List<PJN_Mapping_Label__mdt> {
                new PJN_Mapping_Label__mdt(
                    MasterLabel = 'Mocked Mapping Record Type',
                    DeveloperName = 'PJN_Mocked_Mapping_Label',
                    PJN_Source_Field_API_Name__c = 'Subject,Status',
                    PJN_Target_Field_API_Name__c = 'Description',
                    PJN_Label_Text_Area__c = 'Subject: {0}, {1}',
                    PJN_Mapping__r = mapping
                )
            };
        }
    }
}