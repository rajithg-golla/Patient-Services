@IsTest
public with sharing class LeadToEmailHdlrTestMVN {

    @isTest
    private static void itShouldInsertSuccessfully() {
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        echosign_dev1__Agreement_Template__c template = createAdobeSignTemplate();

        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Libtayo Marketing Consumer').getRecordTypeId();
        Lead consumer  = new Lead(
            FirstName = 'Dean',
            LastName = 'Martin',
            Enrollment_Type_MVN__c = 'Patient',
            LeadSource = 'Website',
            Prescribed_MVN__c = 'Yes',
            Email = 'dean.martin@Libtayo.com',
            RecordTypeId = recordTypeId
        );
        insert consumer;

        echosign_dev1__SIGN_Agreement__c agreementObject =  new echosign_dev1__SIGN_Agreement__c(
            Name = template.echosign_dev1__Name__c,
            echosign_dev1__Recipient_Lead__c = consumer.Id,
            echosign_dev1__Process_Template__c = template.echosign_dev1__Data_Mapping__c,
            echosign_dev1__Merge_Mapping__c = template.echosign_dev1__Merge_Mapping__c,
            echosign_dev1__Agreement_Type__c = template.echosign_dev1__Agreement_Type__c,
            CustomConsumer__c = consumer.Id,
            echosign_dev1__Document_Key__c = 'AgreementIdFromAdobe',
            echosign_dev1__Post_Sign_Redirect_URL__c = template.echosign_dev1__Post_Sign_Redirect_URL__c,
            echosign_dev1__Post_Sign_Redirect_Delay__c = template.echosign_dev1__Post_Sign_Redirect_Delay__c,
            echosign_dev1__Recipient_Addresses__c = consumer.Email,
            echosign_dev1__SignatureOrder__c = 'Recipient signs, then I sign',
            echosign_dev1__SignatureType__c = 'e-Signature',
            echosign_dev1__Status__c = 'Out for Signature',
            echosign_dev1__Enable_Hosted_Signing__c = true
        );
        insert agreementObject;

        System.assertEquals(1, [SELECT Id FROM Lead WHERE Id = :consumer.Id].size(), 'Lead should have inserted.');
    }

    private static echosign_dev1__Agreement_Template__c createAdobeSignTemplate() {
        echosign_dev1__Agreement_Template__c template = new echosign_dev1__Agreement_Template__c(
            Name = 'Libtayo Consent',
            echosign_dev1__Name__c = 'Regeneron Consent & Release Form',
            echosign_dev1__Post_Sign_Redirect_URL__c = 'https://www.looktoyourfuture.com/',
            echosign_dev1__Post_Sign_Redirect_Delay__c = 3,
            echosign_dev1__Merge_Mapping__c = buildMergeMapping().Id,
            echosign_dev1__Data_Mapping__c = buildDataMapping().Id
        );
        insert template;
        return template;
    }

    private static echosign_dev1__SIGN_Data_Mapping__c buildDataMapping() {
        echosign_dev1__SIGN_Data_Mapping__c dataMapping = new echosign_dev1__SIGN_Data_Mapping__c(
            Name = 'Libtayo Program Consent Mapping'
        );
        insert dataMapping;

        echosign_dev1__SIGN_Object_Mapping__c objectMapping = new echosign_dev1__SIGN_Object_Mapping__c(
            echosign_dev1__Field_API_Name__c = 'CustomConsumer__c',
            echosign_dev1__Fully_Qualified_API__c = 'CustomConsumer__r',
            echosign_dev1__SIGN_Data_Mapping__c = dataMapping.Id,
            Name = 'Lead'
        );
        insert objectMapping;

        List<echosign_dev1__SIGN_Field_Mapping__c> fieldMappings = new List<echosign_dev1__SIGN_Field_Mapping__c> {
            new echosign_dev1__SIGN_Field_Mapping__c(
                Name = 'FirstName',
                echosign_dev1__SIGN_Object_Mapping__c = objectMapping.Id,
                echosign_dev1__Source__c = '"first"',
                echosign_dev1__Type__c = 'EchoSign Form Field',
                echosign_dev1__Index__c = 1
            ),
            new echosign_dev1__SIGN_Field_Mapping__c(
                Name = 'LastName',
                echosign_dev1__SIGN_Object_Mapping__c = objectMapping.Id,
                echosign_dev1__Source__c = '"last"',
                echosign_dev1__Type__c = 'EchoSign Form Field',
                echosign_dev1__Index__c = 2
            )
        };
        insert fieldMappings;

        return dataMapping;
    }

    private static echosign_dev1__SIGN_Merge_Mapping__c buildMergeMapping() {
        echosign_dev1__SIGN_Merge_Mapping__c mergeMapping = new echosign_dev1__SIGN_Merge_Mapping__c(
            Name = 'Libtayo Program Merge Mapping'
        );

        insert mergeMapping;

        List<echosign_dev1__SIGN_Form_Field_Mapping__c> formFieldMappings = new List<echosign_dev1__SIGN_Form_Field_Mapping__c>{
            new echosign_dev1__SIGN_Form_Field_Mapping__c(
                echosign_dev1__Data_Mapping__c = mergeMapping.Id,
                echosign_dev1__Form_Field_Name__c = '"First Name"',
                echosign_dev1__Index__c = 1
            ),
            new echosign_dev1__SIGN_Form_Field_Mapping__c(
                echosign_dev1__Data_Mapping__c = mergeMapping.Id,
                echosign_dev1__Form_Field_Name__c = '"Last Name"',
                echosign_dev1__Index__c = 2
            )
        };
        insert formFieldMappings;

        List<echosign_dev1__SIGN_Form_Field_Mapping_Entry__c> formFieldMappingEntries = new List<echosign_dev1__SIGN_Form_Field_Mapping_Entry__c> {
            new echosign_dev1__SIGN_Form_Field_Mapping_Entry__c(
                echosign_dev1__Form_Field_Mapping__c = formFieldMappings[0].Id,
                echosign_dev1__Type__c = 'Salesforce Object Field',
                echosign_dev1__Field_Reference_Name__c = 'FirstName',
                echosign_dev1__Object_Reference_Path__c = 'echosign_dev1__Recipient_Lead__r',
                echosign_dev1__Index__c = 1
            ),
            new echosign_dev1__SIGN_Form_Field_Mapping_Entry__c(
                echosign_dev1__Form_Field_Mapping__c = formFieldMappings[1].Id,
                echosign_dev1__Type__c = 'Salesforce Object Field',
                echosign_dev1__Field_Reference_Name__c = 'LastName',
                echosign_dev1__Object_Reference_Path__c = 'echosign_dev1__Recipient_Lead__r',
                echosign_dev1__Index__c = 2
            )
        };
        insert formFieldMappingEntries;

        return mergeMapping;
    }
}