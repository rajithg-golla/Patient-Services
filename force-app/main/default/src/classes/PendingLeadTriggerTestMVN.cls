@isTest
    private with sharing class PendingLeadTriggerTestMVN {

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
        }

        @isTest
        private static void insertOnlySignedPendingLead() {
            Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

            Pending_Lead_MVN__c pendingLead = buildPendingLead();
            insert pendingLead;

            System.assertEquals(1, [SELECT Id FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id AND Lead_MVN__c != NULL].size(), 'Pending Lead should have associated Lead.');
        }

        @isTest
        private static void insertUnsignedPendingLeadWithSignedAgreement() {
            Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

            Pending_Lead_MVN__c pendingLead = buildPendingLead();
            pendingLead.Agreement_Id_MVN__c = 'test1234';
            insert pendingLead;

            echosign_dev1__SIGN_Agreement__c agreement = buildAgreement(pendingLead.Id);
            agreement.echosign_dev1__Status__c = 'Signed';
            insert agreement;

            System.assertEquals(1, [SELECT Id FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id AND Lead_MVN__c != NULL].size(), 'Pending Lead should have associated Lead.');
        }

        @isTest
        private static void insertUnsignedPendingLeadThenUpdate() {
            Test.setMock(HttpCalloutMock.class, new AdobeSignAPIMockMVN());

            Pending_Lead_MVN__c pendingLead = buildPendingLead();
            pendingLead.Agreement_Id_MVN__c = 'test1234';
            insert pendingLead;

            echosign_dev1__SIGN_Agreement__c agreement = buildAgreement(pendingLead.Id);
            agreement.echosign_dev1__Status__c = 'Out for Signature';
            insert agreement;

            System.assertEquals(NULL, [SELECT Lead_MVN__c FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id][0].Lead_MVN__c, 'Pending Lead should not have associated Lead yet.');

            agreement.echosign_dev1__Status__c = 'Signed';
            update agreement;

            pendingLead.Agreement_Status_MVN__c = 'Signed';
            update pendingLead;

            System.assertEquals(1, [SELECT Id FROM Pending_Lead_MVN__c WHERE Id = :pendingLead.Id AND Lead_MVN__c != NULL].size(), 'Pending Lead should have associated Lead.');
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
    }