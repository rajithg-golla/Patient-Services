@IsTest
private class MVN_OrsiniPatientAPITest {

    private static List<Account> accounts;
    private static Account patient;
    private static Account physician;

    @TestSetup
    static void makeData(){
        Test.startTest();
        CareProgram cp = createCareProgram();
        createProgramDataUsePurpose(cp);
        createHealthInfoDataUsePurpose(cp);
        accounts = new List<Account> {
            buildPatient(),
            buildPhysician()
        };
        insert accounts;
        patient = getAccount(accounts, 'PJN_Patient');
        physician = getAccount(accounts, 'PJN_Physician');
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        cis.addAll(buildContactInformations(patient));
        cis.addAll(buildContactInformations(physician));
        Case carePlan = createCarePlan(cp);
        PJN_Fulfillment_Request__c fulfillmentRequest = createFulfillment(carePlan);
        createFiles(fulfillmentRequest);
        Test.stopTest();
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

    private static Account buildPatient() {
        Account patient = new Account (
            FirstName = 'ConnectiveRx Patient',
            LastName = 'Test',
            MVN_Birthdate__c = Date.valueOf('1988-12-06'),
            HealthCloudGA__Gender__pc = 'Male',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        return patient;
    }

    private static Account buildPhysician() {
        Account physician = new Account (
            FirstName = 'ConnectiveRx Patient',
            LastName = 'Test',
            PJN_Professional_Designation__c = 'MD',
            PJN_DEA__c = '123456789',
            PJN_NPI__c = '987654321',
            PJN_SLN__c = '123789456',
            PJN_Specialty__c = 'Anesthesiology',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId()
        );
        return physician;
    }

    private static Account getAccount(List<Account> accounts, String recordTypeDevName) {
        return [
            SELECT
                Id
            FROM
                Account
            WHERE
                Id IN :accounts
            AND
                RecordType.DeveloperName = :recordTypeDevName
            LIMIT 1
        ];
    }

    private static List<PJN_Contact_Information__c> buildContactInformations(Account acc) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Address_Line_1__c = '123 Main Street',
                PJN_Address_Line_2__c = 'Building 1',
                PJN_City__c = 'Chicago',
                PJN_State__c = 'IL',
                PJN_Postal_Code__c = '60606',
                PJN_Country__c = 'United States',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Email__c = 'test@test.test',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Phone__c = '123123123123',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        return cis;
    }

    private static Case createCarePlan(CareProgram careProgram) {
        Case carePlan = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Program__c = careProgram.Id,
            Status = 'Open'
        );
        insert carePlan;
        return carePlan;
    }

    private static PJN_Fulfillment_Request__c createFulfillment(Case carePlan) {
        PJN_Fulfillment_Request__c fulfillment = new PJN_Fulfillment_Request__c (
            PJN_Care_Plan__c = carePlan.Id,
            RecordTypeId = Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName().get('MVN_SP_Triage_Submitted').getRecordTypeId(),
            PJN_Fulfillment_Request_Status__c = Label.MVN_Orsini_Patient_Status_Submitted
        );
        insert fulfillment;
        return fulfillment;
    }

    private static void createFiles(PJN_Fulfillment_Request__c fulfillmentRequest) {
        ContentVersion file = new ContentVersion(
            Description = 'Test file description',
            PathOnClient = 'MyTestFile.txt',
            Title = 'MyTestFile',
            VersionData = Blob.valueOf('populated')
        );
        insert file;
        file = [
            SELECT
                Id,
                ContentDocumentId
            FROM
                ContentVersion
            WHERE
                Id = :file.Id
        ];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = file.ContentDocumentId,
            LinkedEntityId = fulfillmentRequest.Id
        );
        insert cdl;
    }

    @IsTest
    static void testIfOrsiniPatientRetrievesFulfillmentCorrectly() {
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest();
        MVN_OrsiniPatientResponse orsiniPatientResponse;
        Test.startTest();
        orsiniPatientResponse = MVN_OrsiniPatientAPI.handleOrsiniPatientGetAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniPatientResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('success', orsiniPatientResponse.status, 'Orsini Patient API must succeed. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniPatientResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniPatientResponse.fulfillments, 'Fulfillment cannot be null. Error: ' + transactionLogError);
        System.assert(!orsiniPatientResponse.fulfillments.isEmpty(), 'Fulfillment cannot be empty. Error: ' + transactionLogError);
        System.assertEquals(1, orsiniPatientResponse.fulfillments.size(), 'Fulfillment cannot be empty. Error: ' + transactionLogError);
        fulfillment = getFulfillmentRequest();
        System.assertEquals(Label.MVN_Orsini_Patient_Status_Processed, fulfillment.PJN_Fulfillment_Request_Status__c, 'Fulfillment request mut be Processed. Error: ' + transactionLogError);
        System.assertEquals(fulfillment.MVN_Patient_Id__c, orsiniPatientResponse.fulfillments[0].hub_patient_id, 'Hub Patient Id must be the same as the Fulfillment Record. Error: ' + transactionLogError);
        System.assertEquals(fulfillment.PJN_Patient_Last_Name__c, orsiniPatientResponse.fulfillments[0].patient_last_name, 'Patient last name must be the same as the Fulfillment Record. Error: ' + transactionLogError);
        System.assertEquals(fulfillment.PJN_Patient_First_Name__c, orsiniPatientResponse.fulfillments[0].patient_first_name, 'Patient first name must be the same as the Fulfillment Record. Error: ' + transactionLogError);
        // System.assertNotEquals(null, orsiniPatientResponse.fulfillments[0].attachments, 'Attachaments cannot be null in Fulfillment. Error: ' + transactionLogError);
        // System.assert(!orsiniPatientResponse.fulfillments[0].attachments.isEmpty(), 'Fulfillment must have attachments. Error: ' + transactionLogError);
        // System.assert(orsiniPatientResponse.fulfillments[0].attachments[0].filename.startsWith(orsiniPatientResponse.fulfillments[0].hub_patient_id + '_'), 'Attachment file name must starts with HubPatient Id. Error: ' + transactionLogError);
    }

    @IsTest
    static void testIfOrsiniPatientResponseCorrectly() {
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest();
        buildRequestContext(fulfillment);
        MVN_OrsiniPatientResponse orsiniPatientResponse;
        Test.startTest();
        orsiniPatientResponse = MVN_OrsiniPatientAPI.handleOrsiniPatientPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniPatientResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('success', orsiniPatientResponse.status, 'Orsini Patient API must succeed. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniPatientResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniPatientResponse.fulfillments, 'Fulfillment must be null. Error: ' + transactionLogError);
        fulfillment = getFulfillmentRequest();
        System.assertEquals('Success', fulfillment.MVN_SP_Patient_Triage_Status__c, 'Fulfillment must succeed, Error: ' + fulfillment.MVN_SP_Patient_Triage_Error__c);
        System.assertEquals(null, fulfillment.MVN_SP_Patient_Triage_Error__c, 'Fulfillment must succeed.');
    }

    @IsTest
    static void testIfOrsiniPatientResponseWrong() {
        buildRequestContext(null);
        MVN_OrsiniPatientResponse orsiniPatientResponse;
        Test.startTest();
        orsiniPatientResponse = MVN_OrsiniPatientAPI.handleOrsiniPatientPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assert(String.IsNotBlank(transactionLogError), 'Transaction Log error message cannot be null.');
        System.assertNotEquals(null, orsiniPatientResponse, 'Response cannot be null.');
        System.assertEquals('success', orsiniPatientResponse.status, 'Orsini Patient API must succeed.');
        System.assertEquals(null, orsiniPatientResponse.message, 'Message cannot be null in the response.');
        System.assertEquals(null, orsiniPatientResponse.fulfillments, 'Fulfillment must be null.');
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest();
        System.assertEquals(null, fulfillment.MVN_SP_Patient_Triage_Status__c, 'Fulfillment cannot have any status, Error: ' + fulfillment.MVN_SP_Patient_Triage_Error__c);
        System.assertEquals(null, fulfillment.MVN_SP_Patient_Triage_Error__c, 'Fulfillment must succeed.');
    }

    private static void buildRequestContext(PJN_Fulfillment_Request__c fulfillment) {
        String jsonRequestBody = getJsonRequestBody(fulfillment);

        RestRequest req = new RestRequest();
        req.addHeader('Content-Type', 'application/json');
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('[' + jsonRequestBody + ']'); // Add JSON Message as a POST

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
    }

    private static String getJsonRequestBody(PJN_Fulfillment_Request__c fulfillment) {
        return System.JSON.serializePretty(
            new Map<String, Object> {
                'fulfillment_request_id' => fulfillment != null ? fulfillment.Id : null,
                'status' => 'success',
                'message' => null
            }
        );
    }

    private static PJN_Fulfillment_Request__c getFulfillmentRequest() {
        Map<String, Schema.SObjectField> sobjectFields = Schema.SObjectType.PJN_Fulfillment_Request__c.fields.getMap();
        String fieldNames = '';
        for(String fieldName : sobjectFields.keySet()) {
            fieldNames += fieldName + ',';
        }
        fieldNames = fieldNames.substringBeforeLast(',');
        String query = 'SELECT ' + fieldNames + ' FROM PJN_Fulfillment_Request__c WHERE RecordType.DeveloperName = \'MVN_SP_Triage_Submitted\' LIMIT 1';
        return (PJN_Fulfillment_Request__c) Database.query(query);
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
            transactionLogError = transactionLogs[0].PJN_Callout_Response__c;
        }
        return transactionLogError;
    }
}