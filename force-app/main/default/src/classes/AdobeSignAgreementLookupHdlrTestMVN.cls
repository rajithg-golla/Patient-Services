@isTest
public with sharing class AdobeSignAgreementLookupHdlrTestMVN {

    @TestSetup
    static void makeData(){
        insert new Regeneron_Adobe_Sign_Settings_MVN__c(
            Authentication_Endpoint_MVN__c  = 'https://auth.endpoint.adobe.com',
            Client_Id_MVN__c = 'A-client-id',
            Client_Secret_MVN__c = 'A-client-secret',
            Refresh_Token_MVN__c = 'A-refresh-token',
            REST_API_Endpoint_MVN__c = 'https://rest.endpoint.adobe.com',
            Webhook_Public_Site_MVN__c = 'https://public-site-regeneron.salesforce.com'
        );

        createCareProgram();
    }

    @isTest
    private static void testAgreementOnInsert() {
        // set mock to prevent errors when systm tries to call out.
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Pending_Lead_MVN__c pendingLead = buildPendingLead();
        pendingLead.Agreement_Id_MVN__c = 'test1234';
        insert pendingLead;

        echosign_dev1__SIGN_Agreement__c agreement = buildAgreement(pendingLead.Id);
        agreement.echosign_dev1__Status__c = 'Signed';
        insert agreement;

        pendingLead = [SELECT Id, Lead_MVN__c FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id];

        Case carePlan = buildCarePlan();
        carePlan.Converted_Lead_MVN__c = pendingLead.Lead_MVN__c;
        insert carePlan;

        agreement = [SELECT Care_Plan_MVN__c, CustomConsumer__c, echosign_dev1__Account__c, Pending_Lead_MVN__c FROM echosign_dev1__SIGN_Agreement__c WHERE Id = :agreement.Id][0];

        System.assertNotEquals(null, agreement.Care_Plan_MVN__c, 'The CarePlan Id should be set on the Agreement.');
        System.assertEquals(pendingLead.Lead_MVN__c, agreement.CustomConsumer__c, 'The Lead Id should be populated on the Agreement.');
        System.assertNotEquals(null, agreement.echosign_dev1__Account__c, 'An account should have been created and the Id should have been set on the Agreement.');
    }

    @isTest
    private static void testAgreementOnUpdate() {
        // set mock to prevent errors when systm tries to call out.
        Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

        Pending_Lead_MVN__c pendingLead = buildPendingLead();
        pendingLead.Agreement_Id_MVN__c = 'test1234';
        insert pendingLead;

        echosign_dev1__SIGN_Agreement__c agreement = buildAgreement(pendingLead.Id);
        agreement.echosign_dev1__Status__c = 'Signed';
        insert agreement;

        pendingLead = [SELECT Id, Lead_MVN__c FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id];

        Case carePlan = buildCarePlan();
        insert carePlan;

        carePlan.Converted_Lead_MVN__c = pendingLead.Lead_MVN__c;
        update carePlan;

        agreement = [SELECT Care_Plan_MVN__c, CustomConsumer__c, echosign_dev1__Account__c, Pending_Lead_MVN__c FROM echosign_dev1__SIGN_Agreement__c WHERE Id = :agreement.Id][0];

        System.assertNotEquals(null, agreement.Care_Plan_MVN__c, 'The CarePlan Id should be set on the Agreement.');
        System.assertEquals(pendingLead.Lead_MVN__c, agreement.CustomConsumer__c, 'The Lead Id should be populated on the Agreement.');
        System.assertNotEquals(null, agreement.echosign_dev1__Account__c, 'An account should have been created and the Id should have been set on the Agreement.');
    }


    /******************* HELPER METHODS *******************/
    private static echosign_dev1__SIGN_Agreement__c buildAgreement(Id pendingLeadId) {
        echosign_dev1__Agreement_Template__c template = new echosign_dev1__Agreement_Template__c(
            Name = 'Libtayo Consent',
            echosign_dev1__Name__c = 'Regeneron Consent & Release Form',
            echosign_dev1__Post_Sign_Redirect_URL__c = 'https://www.looktoyourfuture.com/',
            echosign_dev1__Post_Sign_Redirect_Delay__c = 3,
            echosign_dev1__Merge_Mapping__c = createMergeMapping().Id,
            echosign_dev1__Data_Mapping__c = createDataMapping().Id
        );

        echosign_dev1__SIGN_Agreement__c result = new echosign_dev1__SIGN_Agreement__c(
            Name = template.echosign_dev1__Name__c,
            echosign_dev1__Process_Template__c = template.echosign_dev1__Data_Mapping__c,
            echosign_dev1__Merge_Mapping__c = template.echosign_dev1__Merge_Mapping__c,
            echosign_dev1__Agreement_Type__c = template.echosign_dev1__Agreement_Type__c,
            echosign_dev1__Document_Key__c = 'AgreementIdFromAdobe',
            echosign_dev1__Post_Sign_Redirect_URL__c = template.echosign_dev1__Post_Sign_Redirect_URL__c,
            echosign_dev1__Post_Sign_Redirect_Delay__c = template.echosign_dev1__Post_Sign_Redirect_Delay__c,
            echosign_dev1__SignatureOrder__c = 'Recipient signs, then I sign',
            echosign_dev1__SignatureType__c = 'e-Signature',
            echosign_dev1__Enable_Hosted_Signing__c = true,
            Pending_Lead_MVN__c = pendingLeadId
        );
        return result;
    }

    private static Case buildCarePlan() {
        Account programParticipant = createParticipant();

        Case carePlan = new Case (
            AccountId = programParticipant.Id,
            Care_Plan_Template_Ext_ID_Override_MVN__c = 'Test_CPT',
            PJN_Program__c = [SELECT Id FROM CareProgram WHERE Name = 'Test'].Id,
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Libtayo_Marketing_Care_Plan_MVN').getRecordTypeId()
        );

        return carePlan;
    }

    private static Pending_Lead_MVN__c buildPendingLead() {
        Pending_Lead_MVN__c result = new Pending_Lead_MVN__c(
            Agreement_Status_MVN__c = 'Out for Signature',
            BirthDate_MVN__c = Date.today().addYears(-40),
            City_MVN__c = 'Grand Rapids',
            Consumer_has_consented_to_the_prog_MVN__c = 'Yes',
            Consumer_Status_MVN__c = 'Enrolled',
            Diagnosis_MVN__c = 'BCC',
            Email_MVN__c = 'test@test.com',
            Email_Opt_In_MVN__c = 'Yes',
            Enrollment_Type_MVN__c = 'Patient',
            FirstName_MVN__c = 'Jane',
            JSON_Received_MVN__c = '{}',
            LastName_MVN__c = 'Doe',
            Mail_Opt_In_MVN__c = 'Yes',
            Patient_Starter_Kit_MVN__c = 'Yes',
            Phone_MVN__c = '5555555555',
            Phone_Opt_In_MVN__c = 'Yes',
            Phone_Type_MVN__c = 'Mobile',
            Postal_Code_MVN__c = '49503',
            Prescribed_MVN__c = 'Yes',
            State_MVN__c = 'MI',
            Street_MVN__c = '100 Crescent St NE',
            Treatment_Start_Date_Known_MVN__c = 'Yes',
            Treatment_Status_MVN__c = 'Began_Treatment',
            Voice_Messages_OK_MVN__c = 'Yes'
        );
        return result;
    }

    private static CareProgram createCareProgram() {
        CareProgram program = new CareProgram(
            Name = 'Test',
            PJN_Program_DeveloperName__c = 'libtayo_marketing',
            Status = 'In Progress'
        );

        insert program;
        return program;
    }

    private static echosign_dev1__SIGN_Data_Mapping__c createDataMapping() {
        echosign_dev1__SIGN_Data_Mapping__c dataMapping = new echosign_dev1__SIGN_Data_Mapping__c(
            Name = 'DEDSI Program Consent Mapping'
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

    private static echosign_dev1__SIGN_Merge_Mapping__c createMergeMapping() {
        echosign_dev1__SIGN_Merge_Mapping__c mergeMapping = new echosign_dev1__SIGN_Merge_Mapping__c(
            Name = 'DEDSI Program Merge Mapping'
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

    private static Account createParticipant() {
        Account result = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert result;

        Map<String, RecordTypeInfo> recTypes = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();

        PJN_Contact_Information__c address = new PJN_Contact_Information__c(
            PJN_Address_Line_1__c = '135 Monroe Center St NW',
            PJN_City__c = 'Grand Rapids',
            PJN_State__C = 'MI',
            PJN_Postal_Code__c = '49503',
            PJN_Country__c = 'United States',
            PJN_Account__c = result.Id,
            RecordTypeId = recTypes.get('PJN_Address').getRecordTypeId(),
            PJN_Set_as_Primary__c = true
        );
        insert address;

        PJN_Contact_Information__c phone = new PJN_Contact_Information__c(
            PJN_Phone__c = '5555555555',
            PJN_Account__c = result.Id,
            RecordTypeId = recTypes.get('PJN_Phone').getRecordTypeId(),
            PJN_Set_as_Primary__c = true
        );
        insert phone;

        PJN_Contact_Information__c email = new PJN_Contact_Information__c(
            PJN_Email__c = 'jdoe@test.com',
            PJN_Account__c = result.Id,
            RecordTypeId = recTypes.get('PJN_Email').getRecordTypeId(),
            PJN_Set_as_Primary__c = true
        );
        insert email;

        result.PJN_Primary_Address__c = address.Id;
        result.PJN_Primary_Phone__c = phone.Id;
        result.PJN_Primary_Email__c = email.Id;
        update result;

        return result;
    }
}