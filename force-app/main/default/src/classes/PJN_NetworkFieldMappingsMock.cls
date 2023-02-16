/**
 * Mock for PJN_NetworkFieldMappingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkFieldMappingsMock implements System.StubProvider {

    private static final String PREFIX = Schema.SObjectType.PJN_Network_Field_Mapping__mdt.getKeyPrefix();

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryAllWithValues') {
            return this.queryAllWithValues();
        } else {
            return null;
        }
    }

    /**
     * Mock all Network Field Mappings metadatas
     * @returns `List<PJN_Network_Field_Mapping__mdt>`
     */
    public List<PJN_Network_Field_Mapping__mdt> queryAllWithValues() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        networkFieldMappings.addAll(getAccountNetworkFieldMappings());
        networkFieldMappings.addAll(getAddressNetworkFieldMappings());
        networkFieldMappings.addAll(getLicenseNetworkFieldMappings());
        networkFieldMappings.addAll(getAffiliationNetworkFieldMappings());

        return networkFieldMappings;
    }

    private static List<PJN_Network_Field_Mapping__mdt> getAccountNetworkFieldMappings() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        PJN_Network_Field_Mapping__mdt currentNetworkFieldMappings = new PJN_Network_Field_Mapping__mdt (
            PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                PJN_SObject_Name__c = Account.getSObjectType().getDescribe().getName()
            ),
            PJN_SObject_Record_Type__c = 'PJN_Physician',
            PJN_External_Field_Name__c = 'first_name__v',
            PJN_Field_API_Name__c = 'FirstName',
            PJN_Active__c = true,
            PJN_Required_for_DCR_Transmission__c = true,
            PJN_DCR_Transmission__c = true,
            PJN_Sync_Transmission__c = true,
            Id = PREFIX + '000000000001'
        );

        currentNetworkFieldMappings.PJN_Network_Value_Mappings__r.addAll(
            new List<PJN_Network_Value_Mapping__mdt> {
                new PJN_Network_Value_Mapping__mdt (
                    PJN_External_Value__c = 'VNTest',
                    PJN_Inbound__c = true,
                    PJN_Outbound__c = true,
                    PJN_Value__c = 'Test'
                ),
                new PJN_Network_Value_Mapping__mdt (
                    PJN_External_Value__c = 'VNNoTest',
                    PJN_Inbound__c = true,
                    PJN_Outbound__c = true,
                    PJN_Value__c = 'NoTest'
                )
            }
        );
        networkFieldMappings.add(currentNetworkFieldMappings);

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = Account.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'PJN_Physician',
                PJN_External_Field_Name__c = 'last_name__v',
                PJN_Field_API_Name__c = 'LastName',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '000000000002'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = Account.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'PJN_Physician',
                PJN_External_Field_Name__c = 'phone__v',
                PJN_Field_API_Name__c = 'PersonMobilePhone',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = false,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '000000000003'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = Account.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'PJN_Organization',
                PJN_External_Field_Name__c = 'name__v',
                PJN_Field_API_Name__c = 'Name',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '000000000004'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = Account.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'PJN_Organization',
                PJN_External_Field_Name__c = 'name__v',
                PJN_Field_API_Name__c = 'Name',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '000000000005'
            )
        );

        return networkFieldMappings;
    }

    private static List<PJN_Network_Field_Mapping__mdt> getAddressNetworkFieldMappings() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_Contact_Information__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'address_line_1__v',
                PJN_Field_API_Name__c = 'PJN_Address_Line_1__c',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '100000000001'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_Contact_Information__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'address_line_2__v',
                PJN_Field_API_Name__c = 'PJN_Address_Line_2__c',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = false,
                Id = PREFIX + '100000000002'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_Contact_Information__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'locality__v',
                PJN_Field_API_Name__c = 'PJN_City__c',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = false,
                Id = PREFIX + '100000000003'
            )
        );

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_Contact_Information__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'administrative_area__v',
                PJN_Field_API_Name__c = 'PJN_State__c',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = false,
                Id = PREFIX + '100000000004'
            )
        );

        return networkFieldMappings;
    }

    private static List<PJN_Network_Field_Mapping__mdt> getLicenseNetworkFieldMappings() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_License__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'license_number__v',
                PJN_Field_API_Name__c = 'Name',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = true,
                PJN_DCR_Transmission__c = true,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '200000000001'
            )
        );

        return networkFieldMappings;
    }

    private static List<PJN_Network_Field_Mapping__mdt> getAffiliationNetworkFieldMappings() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = new List<PJN_Network_Field_Mapping__mdt>();

        networkFieldMappings.add(
            new PJN_Network_Field_Mapping__mdt (
                PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                    PJN_SObject_Name__c = PJN_Affiliation__c.getSObjectType().getDescribe().getName()
                ),
                PJN_SObject_Record_Type__c = 'All',
                PJN_External_Field_Name__c = 'parent_hco_vid__v',
                PJN_Field_API_Name__c = 'PJN_Parent_Account__c',
                PJN_Active__c = true,
                PJN_Required_for_DCR_Transmission__c = false,
                PJN_DCR_Transmission__c = false,
                PJN_Sync_Transmission__c = true,
                Id = PREFIX + '300000000001'
            )
        );

        PJN_Network_Field_Mapping__mdt currentNetworkFieldMapping = new PJN_Network_Field_Mapping__mdt (
            PJN_Network_Object__r = new PJN_Network_Object_Setting__mdt (
                PJN_SObject_Name__c = PJN_Affiliation__c.getSObjectType().getDescribe().getName()
            ),
            PJN_SObject_Record_Type__c = 'All',
            PJN_External_Field_Name__c = 'parent_hco_status__v',
            PJN_Field_API_Name__c = 'PJN_Status__c',
            PJN_Active__c = true,
            PJN_Required_for_DCR_Transmission__c = false,
            PJN_DCR_Transmission__c = false,
            PJN_Sync_Transmission__c = true,
            Id = PREFIX + '300000000002'
        );

        currentNetworkFieldMapping.PJN_Network_Value_Mappings__r.addAll(
            new List<PJN_Network_Value_Mapping__mdt> {
                new PJN_Network_Value_Mapping__mdt (
                    PJN_External_Value__c = 'A',
                    PJN_Inbound__c = true,
                    PJN_Outbound__c = true,
                    PJN_Value__c = 'Active'
                ),
                new PJN_Network_Value_Mapping__mdt (
                    PJN_External_Value__c = 'I',
                    PJN_Inbound__c = true,
                    PJN_Outbound__c = true,
                    PJN_Value__c = 'Inactive'
                )
            }
        );
        networkFieldMappings.add(currentNetworkFieldMapping);

        return networkFieldMappings;
    }
}