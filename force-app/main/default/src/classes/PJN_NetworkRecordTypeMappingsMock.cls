/**
 * Mock for PJN_NetworkRecordTypeMappingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkRecordTypeMappingsMock implements System.StubProvider {

    private static final String PREFIX = Schema.SObjectType.PJN_Network_Record_Type_Mapping__mdt.getKeyPrefix();

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryAll') {
            return this.queryAll();
        } else {
            return null;
        }
    }

    /**
     * Mock all Network Record Type Mappings
     * @returns `List<PJN_Network_Record_Type_Mapping__mdt>`
     */
    public List<PJN_Network_Record_Type_Mapping__mdt> queryAll() {
        List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings = new List<PJN_Network_Record_Type_Mapping__mdt>();

        networkRecordTypeMappings.addAll(getAccountNetworkRecordTypeMappings());

        return networkRecordTypeMappings;
    }

    private static List<PJN_Network_Record_Type_Mapping__mdt> getAccountNetworkRecordTypeMappings() {
        List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings = new List<PJN_Network_Record_Type_Mapping__mdt>();

        networkRecordTypeMappings.add(
            new PJN_Network_Record_Type_Mapping__mdt (
                PJN_Network_Object_Setting__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = 'Account'
                ),
                PJN_Record_Type_Name__c = 'PJN_Physician',
                PJN_Network_Record_Type__c = 'HCP',
                PJN_Network_Record_SubType__c = 'P',
                PJN_Inbound__c = true,
                PJN_Outbound__c = true,
                Id = PREFIX + '000000000003'
            )
        );

        networkRecordTypeMappings.add(
            new PJN_Network_Record_Type_Mapping__mdt (
                PJN_Network_Object_Setting__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = 'Account'
                ),
                PJN_Record_Type_Name__c = 'PJN_Organization',
                PJN_Network_Record_Type__c = 'HCO',
                PJN_Network_Record_SubType__c = '4:4',
                PJN_Inbound__c = true,
                PJN_Outbound__c = true,
                Id = PREFIX + '000000000004'
            )
        );

        return networkRecordTypeMappings;
    }
}