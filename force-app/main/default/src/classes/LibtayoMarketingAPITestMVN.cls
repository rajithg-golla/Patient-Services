/**
 * @author      Mavens
 * @description Unit tests for Libtayo Marketing API.
 */
@isTest
public with sharing class LibtayoMarketingAPITestMVN {

    @TestSetup
    static void makeData(){
        createAdobeSignTemplate();
    }

    @isTest
    static void testHttpPostSuccess() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/submit';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"dob":"3/5/1980","enrollmentType":"Patient","prescribed":"Yes","diagnosis":"BCC","treatmentStatus":"Began_Treatment","treatmentStartDateKnown":"Yes","treatmentStartDate":"3/5/2021","lastTreatmentDate":"3/5/2021","patientStarterKit":"Yes","consumerConsented":"Yes","firstName":"John","lastName":"Doe","emailOptIn":"Yes","email":"rlocke@mavens.com","phoneOptIn":"Yes","phone":"6162386096","phoneType":"Mobile","voiceMessagesConsented":"Yes","mailOptIn":"Yes","street":"135 Monroe Center St NW","city":"Grand Rapids","state":"MI","postalCode":"49503","agreementId":"TESTID123"}');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
            LibtayoMarketingAPIMVN.handlePost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Response code should be 200.');
    }

    @isTest
    static void testHttpPostFail() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/submit';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('fail');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
            LibtayoMarketingAPIMVN.handlePost();
        Test.stopTest();

        System.assertEquals(400, res.statusCode, 'Response code should be 500.');
    }

    /******************* HELPER METHODS *******************/
    public static echosign_dev1__Agreement_Template__c createAdobeSignTemplate() {
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
}