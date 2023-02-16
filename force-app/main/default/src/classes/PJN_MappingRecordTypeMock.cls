/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping record type mock provider
 */
@isTest(isParallel=true) public with sharing class PJN_MappingRecordTypeMock implements System.StubProvider {
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
            return new PJN_Mapping_Record_Type__mdt(
                MasterLabel = 'Mocked Mapping Record Type',
                DeveloperName = 'PJN_Mocked_Mapping_record_Type',
                PJN_Record_Type_API_Name__c = 'PJN_Activity',
                PJN_Target_Field_API_Name__c = 'RecordTypeId',
                PJN_Mapping__r = mapping
            );
        }
    }
}