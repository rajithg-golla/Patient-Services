/**
 * @author      Mavens
 * @group       MDM
 * @description Mock for MVN_MDMFieldMappingQuery
 */
@IsTest
public with sharing class MVN_MDMFieldMappingMock implements System.StubProvider {

    private static final String PREFIX = Schema.SObjectType.MVN_MDM_Field_Mapping__mdt.getKeyPrefix();

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
     * Initialize all the MDM Field Mapping metadatas when query all
     * @return  `List<MVN_MDM_Field_Mapping__mdt>`
     */
    public List<MVN_MDM_Field_Mapping__mdt> queryAll() {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();

        mdmFieldMappings.addAll(getAccountMDMFieldMappings());
        mdmFieldMappings.addAll(getPAPMDMFieldMappings());
        mdmFieldMappings.addAll(getCopayMDMFieldMappings());
        mdmFieldMappings.addAll(getConsentMDMFieldMappings());

        return mdmFieldMappings;
    }

    private static List<MVN_MDM_Field_Mapping__mdt> getAccountMDMFieldMappings() {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000001',
                Label = 'MyRare:Account:FirstName',
                DeveloperName = 'MVN_MyRare_Account_FirstName',
                MasterLabel = 'MVN_MyRare_Account_FirstName',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'firstname',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'FirstName',
                Id = PREFIX + '000000000001'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000001',
                Label = 'MyRare:Account:LastName',
                DeveloperName = 'MVN_MyRare_Account_LastName',
                MasterLabel = 'MVN_MyRare_Account_LastName',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'lastname',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'LastName',
                Id = PREFIX + '000000000002'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000001',
                Label = 'MyRare:Account:BirthDate',
                DeveloperName = 'MVN_MyRare_Account_BirthDate',
                MasterLabel = 'MVN_MyRare_Account_BirthDate',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'dateOfBirth',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Birthdate__c',
                Id = PREFIX + '000000000003'
            )
        );

        return mdmFieldMappings;
    }

    private static List<MVN_MDM_Field_Mapping__mdt> getPAPMDMFieldMappings() {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000002',
                Label = 'MyRare:Account:FPL',
                DeveloperName = 'MVN_MyRare_Account_FPL',
                MasterLabel = 'MVN_MyRare_Account_FPL',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'fpl',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'PJN_Federal_Poverty_Level_Percentage__c',
                Id = PREFIX + '100000000001'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000002',
                Label = 'MyRare:PAP:HouseHoldIncome',
                DeveloperName = 'MVN_MyRare_Account_HouseHoldIncome',
                MasterLabel = 'MVN_MyRare_Account_HouseHoldIncome',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'householdincome',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'PJN_Estimated_Household_Income__c',
                Id = PREFIX + '100000000002'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000002',
                Label = 'MyRare:PAP:HouseHoldSize',
                DeveloperName = 'MVN_MyRare_PAP_HouseHoldSize',
                MasterLabel = 'MVN_MyRare_PAP_HouseHoldSize',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'householdsize',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'PJN_Estimated_Household_Size__c',
                Id = PREFIX + '100000000003'
            )
        );

        return mdmFieldMappings;
    }

    private static List<MVN_MDM_Field_Mapping__mdt> getCopayMDMFieldMappings() {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:CommercialPrivateInsurance',
                DeveloperName = 'MVN_MyRare_Copay_CommercialPrivateInsura',
                MasterLabel = 'MVN_MyRare_Copay_CommercialPrivateInsura',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'commercialprivateinsurance',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Commercial_Private_Insurance__c',
                Id = PREFIX + '300000000001'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:InsurancePCN',
                DeveloperName = 'MVN_MyRare_Copay_InsurancePCN',
                MasterLabel = 'MVN_MyRare_Copay_InsurancePCN',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'insurancepcn',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Copay_PCN__c',
                Id = PREFIX + '300000000002'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:EnrollmentSuccessful',
                DeveloperName = 'MVN_MyRare_Copay_EnrollmentSuccessful',
                MasterLabel = 'MVN_MyRare_Copay_EnrollmentSuccessful',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'enrollmentsuccessful',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Enrollment_Successful__c',
                Id = PREFIX + '300000000003'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:GovernmentProgram',
                DeveloperName = 'MVN_MyRare_Copay_GovernmentProgram',
                MasterLabel = 'MVN_MyRare_Copay_GovernmentProgram',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'governmentprogram',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Government_Sponsored_Program__c',
                Id = PREFIX + '300000000004'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:HasInsurance',
                DeveloperName = 'MVN_MyRare_Copay_HasInsurance',
                MasterLabel = 'MVN_MyRare_Copay_HasInsurance',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'hasinsurance',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Insurance__c',
                Id = PREFIX + '300000000005'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:HasPrescription',
                DeveloperName = 'MVN_MyRare_Copay_HasPrescription',
                MasterLabel = 'MVN_MyRare_Copay_HasPrescription',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'hasprescription',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Has_Prescription__c',
                Id = PREFIX + '300000000006'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:InsuranceBIN',
                DeveloperName = 'MVN_MyRare_Copay_InsuranceBIN',
                MasterLabel = 'MVN_MyRare_Copay_InsuranceBIN',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'insurancebin',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Copay_BIN__c',
                Id = PREFIX + '300000000007'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:InsuranceGroupNumber',
                DeveloperName = 'MVN_MyRare_Copay_InsuranceGroupNumber',
                MasterLabel = 'MVN_MyRare_Copay_InsuranceGroupNumber',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'insurancegroupnumber',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Copay_Group_Number__c',
                Id = PREFIX + '300000000008'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:InsuranceMemberNumber',
                DeveloperName = 'MVN_MyRare_Copay_InsuranceMemberNumber',
                MasterLabel = 'MVN_MyRare_Copay_InsuranceMemberNumber',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'insurancemembernumber',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_Copay_Member_Id__c',
                Id = PREFIX + '300000000009'
            )
        );

        mdmFieldMappings.add(
            new MVN_MDM_Field_Mapping__mdt (
                MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000003',
                Label = 'MyRare:Copay:USResident',
                DeveloperName = 'MVN_MyRare_Copay_USResident',
                MasterLabel = 'MVN_MyRare_Copay_USResident',
                MVN_Inbound__c = true,
                MVN_Is_Active__c = true,
                MVN_MDM_Field__c = 'usResident',
                MVN_Outbound__c = true,
                MVN_SFDC_Field__c = 'MVN_US_Resident__c',
                Id = PREFIX + '300000000010'
            )
        );

        return mdmFieldMappings;
    }

    private static List<MVN_MDM_Field_Mapping__mdt> getConsentMDMFieldMappings() {
        List<MVN_MDM_Field_Mapping__mdt> mdmFieldMappings = new List<MVN_MDM_Field_Mapping__mdt>();

        MVN_MDM_Field_Mapping__mdt currentMDMFieldMapping = new MVN_MDM_Field_Mapping__mdt (
            MVN_MDM_Object_Setting__c = MVN_MDMObjectSettingMock.PREFIX + '000000000004',
            Label = 'MyRare:Consent:Name',
            DeveloperName = 'MVN_MyRare_Consent_Name',
            MasterLabel = 'MVN_MyRare_Consent_Name',
            MVN_Inbound__c = true,
            MVN_Is_Active__c = true,
            MVN_Is_Lookup_Field__c = true,
            MVN_Lookup_Field_Filter__c = 'Name',
            MVN_Lookup_sObject__c = 'DataUsePurpose',
            MVN_MDM_Field__c = 'consentname',
            MVN_Outbound__c = true,
            MVN_SFDC_Field__c = 'PJN_Data_Use_Purpose__c',
            Id = PREFIX + '300000000010'
        );

        currentMDMFieldMapping.MVN_MDM_Value_Mappings__r.addAll(
            new List<MVN_MDM_Value_Mapping__mdt> {
                new MVN_MDM_Value_Mapping__mdt (
                    MVN_Inbound__c = true,
                    MVN_Is_Active__c = true,
                    MVN_MDM_Value__c = 'testprogram',
                    MVN_Outbound__c = true,
                    MVN_SFDC_Value__c = 'TestProgram'
                ),
                new MVN_MDM_Value_Mapping__mdt (
                    MVN_Inbound__c = true,
                    MVN_Is_Active__c = true,
                    MVN_MDM_Value__c = 'testdisclose',
                    MVN_Outbound__c = true,
                    MVN_SFDC_Value__c = 'Disclose/Use Health Information'
                )
            }
        );
        mdmFieldMappings.add(currentMDMFieldMapping);

        return mdmFieldMappings;
    }
}