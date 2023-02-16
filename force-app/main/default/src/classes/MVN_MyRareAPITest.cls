/**
 * @author      Mavens
 * @group       MyRare.com
 * @description Test for apex class MVN_MyRareAPI
 */
@IsTest
private class MVN_MyRareAPITest {

    private static final String ATTACHMENT_BODY = 'JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwogIC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAvTWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0KPj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAgL1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9udAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2JqCgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVuZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAwMDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G';

    static {
        String jsonRequestBody = getJsonRequestBody();

        RestRequest req = new RestRequest();
        req.addHeader('Content-Type', 'application/json');
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonRequestBody); // Add JSON Message as a POST

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        MVN_MDMConnectionUtil.mdmConnectionQuery = (MVN_MDMConnectionQuery) Test.createStub(MVN_MDMConnectionQuery.class, new MVN_MDMConnectionMock());
        MVN_MDMConnectionUtil.mdmObjectSettingQuery = (MVN_MDMObjectSettingQuery) Test.createStub(MVN_MDMObjectSettingQuery.class, new MVN_MDMObjectSettingMock());
        MVN_MDMConnectionUtil.mdmFieldMappingQuery = (MVN_MDMFieldMappingQuery) Test.createStub(MVN_MDMFieldMappingQuery.class, new MVN_MDMFieldMappingMock());
    }

    @TestSetup
    static void makeData(){
        Test.startTest();
        CareProgram cp = createCareProgram();
        createProgramDataUsePurpose(cp);
        createHealthInfoDataUsePurpose(cp);
        Test.stopTest();
    }

    private static String getJsonRequestBody() {
        return System.JSON.serializePretty(
            new Map<String, Object> {
                'arxId' => '1234567890',
                'type' => 'Consent',
                'patient' => getPatientRequest(),
                'income' => getIncomeRequests(),
                'consents' => getConsentRequests(),
                'insurance' => getInsuranceRequest(),
                'attachments' => getAttachmentRequests()
            }
        );
    }

    private static Object getPatientRequest() {
        return new Map<String, Object> {
            'patientid' => '89215832947',
            'firstname' => 'ConnectiveRx Patient',
            'lastname' => 'Test',
            'dateofbirth' => '1988-12-06'
        };
    }

    private static Object getIncomeRequests() {
        List<Object> incomes = new List<Object>();
        incomes.add(
            new Map<String, Object> {
                'householdincome' => '1234567890',
                'householdsize' => '12',
                'fpl' => '39.92'
            }
        );
        return incomes;
    }

    private static Object getConsentRequests() {
        List<Object> consents = new List<Object>();
        consents.add(
            new Map<String, Object> {
                'consentname' => 'TestProgram',
                'consentprovidedby' => 'Whatever',
                'effectivedate' => '2021-05-18',
                'expirationdate' => '2021-08-18'
            }
        );
        consents.add(
            new Map<String, Object> {
                'consentname' => 'TestDisclose',
                'consentprovidedby' => 'Whatever',
                'effectivedate' => '2021-04-15',
                'expirationdate' => '2021-10-22'
            }
        );
        return consents;
    }

    private static Object getInsuranceRequest() {
        return new Map<String, Object> {
            'hasprescription' => 'yes',
            'usresident' => 'yes',
            'commercialprivateinsurance' => 'no',
            'governmentprogram' => 'no',
            'hasinsurance' => 'yes',
            'enrollmentsuccessful' => 'yes',
            'insurancegroupnumber' => '123123123',
            'insurancemembernumber' => '456456456',
            'insurancebin' => '789789',
            'insurancepcn' => '2335623546'
        };
    }

    private static Object getAttachmentRequests() {
        List<Object> attachments = new List<Object>();
        attachments.add(
            new Map<String, Object> {
                'filename' => 'enrollmentPdfForm.pdf',
                'attachmentid' => '123123456456789',
                'descriptor' => 'Description for the PDF Enrollment form',
                'content' => ATTACHMENT_BODY
            }
        );
        attachments.add(
            new Map<String, Object> {
                'filename' => 'myAttachment1.pdf',
                'attachmentid' => '12394123089125',
                'descriptor' => 'Description for the file attachment 1',
                'content' => ATTACHMENT_BODY
            }
        );
        return attachments;
    }

    private static CareProgram createCareProgram() {
        CareProgram cp;
        try {
            cp = [
                SELECT
                    Id
                FROM
                    CareProgram
                WHERE
                    PJN_Program_DeveloperName__c = :Label.MVN_MyRare_Enrollment_ProgramDevName
            ];
        } catch (System.QueryException ex) {
            cp = new CareProgram(
                Name = 'Test Program',
                PJN_Program_DeveloperName__c = Label.MVN_MyRare_Enrollment_ProgramDevName,
                StartDate = Date.today()
            );
            insert cp;
        }
        return cp;
    }

    static void createProgramDataUsePurpose(CareProgram careProgram) {
        try {
            DataUsePurpose dup = [
                SELECT
                    Id
                FROM
                    DataUsePurpose
                WHERE
                    Name = 'TestProgram'
            ];
        } catch (System.QueryException ex) {
            insert new DataUsePurpose(
                Name = 'TestProgram',
                PJN_Effective_Months__c = 12,
                PurposeId = careProgram.Id,
                PJN_External_Id__c = 'MVN_Test_ProgramConsent'
            );
        }
    }

    static void createHealthInfoDataUsePurpose(CareProgram careProgram) {
        try {
            DataUsePurpose dup = [
                SELECT
                    Id
                FROM
                    DataUsePurpose
                WHERE
                    Name = 'Disclose/Use Health Information'
            ];
        } catch (System.QueryException ex) {
            insert new DataUsePurpose(
                Name = 'Disclose/Use Health Information',
                PJN_Effective_Months__c = 12,
                PurposeId = careProgram.Id,
                PJN_External_Id__c = 'MVN_Test_HealthInformationPrg'
            );
        }
    }

    private static User getRunningUser() {
        try {
            return [
                SELECT
                    Id
                FROM
                    User
                WHERE
                    Profile.Name = 'Integration User'
                AND
                    IsActive = true
                LIMIT 1
            ];
        } catch (System.QueryException ex) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Integration User'  LIMIT 1];
            User psUser = new User(alias = 'mvnrgnintusr', email='test@mavens.rgn.com', emailencodingkey='UTF-8',
                FirstName = 'Test', Lastname='User', languagelocalekey='en_US',  localesidkey='en_US',
                profileid = p.Id, timezonesidkey='America/Los_Angeles', isActive = true,
                username='test@mavens.rgn.com'
            );
            insert psUser;
            return psUser;
        }
    }

    @IsTest
    static void testIfRequestNoPatientIsIngestedCorrectly() {
        Test.startTest();
        MVN_MyRareAPI.handleMyRarePostAPI();
        Test.stopTest();
        List<Case> caseRequests = getCaseRequests();
        String transactionLogError = getTransactionLogError();
        System.assert(!caseRequests.isEmpty(), 'Request has not been created.Error: ' + transactionLogError);
        System.assertEquals(1, caseRequests.size(), 'Only one request should be created. Error: ' + transactionLogError);
        System.assertEquals(Label.MVN_MyRare_Enrollment_Consent_Subject, caseRequests[0].Subject, 'Wrong Subject. Error: ' + transactionLogError);
        System.assertEquals('Open', caseRequests[0].Status, 'Wrong Status. Error: ' + transactionLogError);
        System.assertEquals(null, caseRequests[0].AccountId, 'Wrong Patient. Error: ' + transactionLogError);
        System.assertEquals(null, caseRequests[0].ParentId, 'Wrong CarePlan. Error: ' + transactionLogError);
        System.assertNotEquals(null, caseRequests[0].PJN_Program__c, 'Program is not assigned correctly. Error: ' + transactionLogError);
        List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(caseRequests[0]);
        System.assert(!contentDocumentLinks.isEmpty(), 'Files have not been created. Error: ' + transactionLogError);
        System.assertEquals(2, contentDocumentLinks.size(), 'Two files should be created only. Error: ' + transactionLogError);
    }

    @IsTest
    static void testIfRequestWithPatientIsIngestedCorrectly() {
        createPatientAndCarePlan();
        Test.startTest();
        MVN_MyRareAPI.handleMyRarePostAPI();
        Test.stopTest();
        List<Case> caseRequests = getCaseRequests();
        String transactionLogError = getTransactionLogError();
        /*
        System.assert(!caseRequests.isEmpty(), 'Request has not been created. Error: ' + transactionLogError);
        System.assertEquals(1, caseRequests.size(), 'Only one request should be created. Error: ' + transactionLogError);
        System.assertEquals(Label.MVN_MyRare_Enrollment_Consent_Subject, caseRequests[0].Subject, 'Wrong Subject. Error: ' + transactionLogError);
        System.assertEquals('Open', caseRequests[0].Status, 'Wrong Status. Error: ' + transactionLogError);
        System.assertNotEquals(null, caseRequests[0].AccountId, 'Wrong Patient. Error: ' + transactionLogError);
        System.assertNotEquals(null, caseRequests[0].ParentId, 'Wrong CarePlan. Error: ' + transactionLogError);
        System.assertNotEquals(null, caseRequests[0].PJN_Program__c, 'Program is not assigned correctly. Error: ' + transactionLogError);
        List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(caseRequests[0]);
        System.assert(!contentDocumentLinks.isEmpty(), 'Files have not been created. Error: ' + transactionLogError);
        System.assertEquals(2, contentDocumentLinks.size(), 'Two files should be created only. Error: ' + transactionLogError);
        */
    }

    private static List<Case> getCaseRequests() {
        return [
            SELECT
                Id,
                Subject,
                Description,
                HealthCloudGA__DueDate__c,
                Status,
                AccountId,
                ParentId,
                PJN_Program__c
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'PJN_Request'
        ];
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Case caseRequest) {
        return [
            SELECT
                Id,
                LinkedEntityId,
                ContentDocumentId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :caseRequest.Id
        ];
    }

    private static void createPatientAndCarePlan() {
        Account patient = new Account (
            FirstName = 'ConnectiveRx Patient',
            LastName = 'Test',
            MVN_Birthdate__c = Date.valueOf('1988-12-06'),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        insert patient;
        Test.setFixedSearchResults(new List<Id> {patient.Id});
        insert new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Program__c = getCareProgramId(),
            Status = 'Open'
        );
    }

    private static Id getCareProgramId() {
        CareProgram cp = [
            SELECT
                Id
            FROM
                CareProgram
            WHERE
                PJN_Program_DeveloperName__c = :Label.MVN_MyRare_Enrollment_ProgramDevName
        ];
        return cp.Id;
    }

    private static String getTransactionLogError() {
        List<PJN_Transaction_Log_Object__c> transactionLogs = [
            SELECT
                Id,
                PJN_Callout_Request__c,
                PJN_Callout_Response__c,
                PJN_Incoming_URL__c,
                PJN_Level__c,
                PJN_Record_Related__c,
                PJN_Running_User__c,
                PJN_Type__c,
                PJN_Message__c
            FROM
                PJN_Transaction_Log_Object__c
        ];
        String transactionLogError;
        if (!transactionLogs.isEmpty()) {
            transactionLogError = transactionLogs[0].PJN_Message__c;
        }
        return transactionLogError;
    }
}