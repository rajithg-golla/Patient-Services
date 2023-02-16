/**
 * Mock for PJN_NetworkStatusMapping
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_ObjectFieldContactInfoMappingsMock implements System.StubProvider {

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
     * Mock all Network status mapping metadatas
     * @returns `List<PJN_Object_Field_Contact_Info_Mapping__mdt>`
     */
    public List<PJN_Object_Field_Contact_Info_Mapping__mdt> queryAll() {
        List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings = new List<PJN_Object_Field_Contact_Info_Mapping__mdt>();

        objectFieldContactInfoMappings.add(
            new PJN_Object_Field_Contact_Info_Mapping__mdt(
                Label = 'Account: PersonEmail to Contact Info',
                DeveloperName = 'PJN_Account_PersonEmail_ContactInfo',
                PJN_Contact_Info_Field_Name__c = 'PJN_Email__c',
                PJN_Contact_Info_Record_Type__c = 'PJN_Email',
                PJN_Contact_Info_Type__c = 'Work',
                PJN_Field_Name__c = 'PersonEmail',
                PJN_Object_Name__c = 'Account'
            )
        );

        objectFieldContactInfoMappings.add(
            new PJN_Object_Field_Contact_Info_Mapping__mdt(
                Label = 'Account: Phone to Contact Info',
                DeveloperName = 'PJN_Account_Phone_ContactInfo',
                PJN_Contact_Info_Field_Name__c = 'PJN_Phone__c',
                PJN_Contact_Info_Record_Type__c = 'PJN_Phone',
                PJN_Contact_Info_Type__c = 'Home',
                PJN_Field_Name__c = 'Phone',
                PJN_Object_Name__c = 'Account'
            )
        );

        objectFieldContactInfoMappings.add(
            new PJN_Object_Field_Contact_Info_Mapping__mdt(
                Label = 'Address: Email to Contact Info',
                DeveloperName = 'PJN_Address_Email_ContactInfo',
                PJN_Contact_Info_Field_Name__c = 'PJN_Email__c',
                PJN_Contact_Info_Record_Type__c = 'PJN_Email',
                PJN_Contact_Info_Type__c = 'Work',
                PJN_Field_Name__c = 'PJN_Email__c',
                PJN_Object_Name__c = 'PJN_Contact_Information__c'
            )
        );

        objectFieldContactInfoMappings.add(
            new PJN_Object_Field_Contact_Info_Mapping__mdt(
                Label = 'Address: Phone to Contact Info',
                DeveloperName = 'PJN_Address_Phone_ContactInfo',
                PJN_Contact_Info_Field_Name__c = 'PJN_Phone__c',
                PJN_Contact_Info_Record_Type__c = 'PJN_Phone',
                PJN_Contact_Info_Type__c = 'Home',
                PJN_Field_Name__c = 'PJN_Phone__c',
                PJN_Object_Name__c = 'PJN_Contact_Information__c'
            )
        );

        return objectFieldContactInfoMappings;
    }
}