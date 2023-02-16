@IsTest
private class MVN_OrsiniStatusAPITest {

    private static final Integer BULK_DATA = 200;
    private static List<Account> patients;

    @TestSetup
    static void makeData(){
        Test.startTest();
        CareProgram cp = createCareProgram();
        createProgramDataUsePurpose(cp);
        createHealthInfoDataUsePurpose(cp);
        patients = createPatients();
        createCarePlans(cp);
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

    private static List<Account> createPatients() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < BULK_DATA; i++) {
            accounts.add(
                new Account (
                    FirstName = 'ConnectiveRx Patient',
                    LastName = 'Test',
                    MVN_Birthdate__c = Date.valueOf('1988-12-06'),
                    HealthCloudGA__Gender__pc = 'Male',
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
                )
            );
        }
        insert accounts;
        return accounts;
    }

    private static void createCarePlans(CareProgram careProgram) {
        List<Case> carePlans = new List<Case>();
        for (Account patient : patients) {
            carePlans.add(
                new Case (
                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                    AccountId = patient.Id,
                    PJN_Program__c = careProgram.Id,
                    Status = 'Open'
                )
            );
        }
        insert carePlans;
    }

    @IsTest
    static void testIfSPStatusWorksCorrectly() {
        List<Case> carePlans = getCarePlans();
        buildRequestContext(carePlans, true);
        MVN_OrsiniStatusResponse orsiniStatusResponse;
        Test.startTest();
        orsiniStatusResponse = MVN_OrsiniStatusAPI.handleOrsiniStatusPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniStatusResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('success', orsiniStatusResponse.status, 'Orsini Patient API must succeed. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniStatusResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniStatusResponse.events, 'Events cannot be null. Error: ' + transactionLogError);
        System.assert(!orsiniStatusResponse.events.isEmpty(), 'Events cannot be empty. Error: ' + transactionLogError);
        for (MVN_OrsiniEventResult eventResult : orsiniStatusResponse.events) {
            System.assert(eventResult.success, 'Event must succeed. Error: ' + transactionLogError);
            System.assertEquals(null, eventResult.message, 'Event message must be null. Error: ' + transactionLogError);
        }
        List<PJN_Event__c> events = getEvents(carePlans);
        System.assertEquals(carePlans.size(), events.size(), 'Events must match number of CarePlans. Error: ' + transactionLogError);
        for (PJN_Event__c event : events) {
            System.assertNotEquals(null, event.PJN_Patient__r.MVN_Patient_Id__c, 'Patient Id cannot be null. Error: ' + transactionLogError);
            System.assertNotEquals(null, event.PJN_Case__c, 'CarePlan Id cannot be null. Error: ' + transactionLogError);
            System.assertNotEquals(null, event.PJN_SP_Patient_Id__c, 'SP Patient Id cannot be null. Error: ' + transactionLogError);
            System.assertEquals(event.PJN_SP_Patient_Id__c, event.PJN_Case__r.MVN_SP_Patient_Id__c, 'CarePlan SP Patient Id cannot be null. Error: ' + transactionLogError);
            System.assertEquals('Pending', event.PJN_Status__c, 'Status must be Pending. Error: ' + transactionLogError);
            System.assertEquals('P01', event.PJN_Sub_Status__c, 'SubStatus must be P01. Error: ' + transactionLogError);
            System.assertEquals(System.today(), event.PJN_Status_Date__c, 'Status date must be today. Error: ' + transactionLogError);
        }
    }

    @IsTest
    static void testIfSPStatusWorksNoEvent() {
        List<Case> carePlans = new List<Case>();
        buildRequestContext(carePlans, true);
        MVN_OrsiniStatusResponse orsiniStatusResponse;
        Test.startTest();
        orsiniStatusResponse = MVN_OrsiniStatusAPI.handleOrsiniStatusPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniStatusResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('error', orsiniStatusResponse.status, 'Orsini Patient API must error. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniStatusResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniStatusResponse.events, 'Events must be null. Error: ' + transactionLogError);
    }

    @IsTest
    static void testIfSPStatusWorksWrong() {
        List<Case> carePlans = getCarePlans();
        buildRequestContext(carePlans, false);
        MVN_OrsiniStatusResponse orsiniStatusResponse;
        Test.startTest();
        orsiniStatusResponse = MVN_OrsiniStatusAPI.handleOrsiniStatusPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniStatusResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('error', orsiniStatusResponse.status, 'Orsini Patient API must error. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniStatusResponse.events, 'Events cannot be null. Error: ' + transactionLogError);
        System.assert(!orsiniStatusResponse.events.isEmpty(), 'Events cannot be empty. Error: ' + transactionLogError);
        Boolean oneIsSuccess = false;
        for (MVN_OrsiniEventResult eventResult : orsiniStatusResponse.events) {
            System.assert(!eventResult.success || !oneIsSuccess, 'Event must be wrong. Error: ' + transactionLogError);
            System.assert(eventResult.message != null || !oneIsSuccess, 'Event message must be null. Error: ' + transactionLogError);
            oneIsSuccess = oneIsSuccess || eventResult.success;
        }
        List<PJN_Event__c> events = getEvents(carePlans);
        System.assertEquals(1, events.size(), 'Only one event should be created. Error: ' + transactionLogError);
    }

    private static List<Case> getCarePlans() {
        return [
            SELECT
                Id,
                Account.MVN_Patient_Id__c
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'CarePlan'
        ];
    }
    private static void buildRequestContext(List<Case> carePlans, Boolean hasPatientId) {
        String jsonRequestBody = getJsonRequestBody(carePlans, hasPatientId);

        RestRequest req = new RestRequest();
        req.addHeader('Content-Type', 'application/json');
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonRequestBody); // Add JSON Message as a POST

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
    }

    private static String getJsonRequestBody(List<Case> carePlans, Boolean hasPatientId) {
        List<MVN_OrsiniStatusRequest> requests = new List<MVN_OrsiniStatusRequest>();
        Boolean oneAtLeast = false;
        for (Case carePlan : carePlans) {
            MVN_OrsiniStatusRequest request = new MVN_OrsiniStatusRequest();
            request.pharmacy_patient_id = hasPatientId || !oneAtLeast ? carePlan.Account.MVN_Patient_Id__c : '1234567890';
            request.hub_patient_id = hasPatientId || !oneAtLeast ? carePlan.Account.MVN_Patient_Id__c : '1234567890';
            request.status = 'Pending';
            request.substatus = 'P01';
            request.substatus_description = 'New Referral';
            request.status_date = System.now();
            requests.add(request);
            oneAtLeast = true;
        }
        return System.JSON.serializePretty(requests);
    }

    private static List<PJN_Event__c> getEvents(List<Case> carePlans) {
        return [
            SELECT
                Id,
                PJN_Case__c,
                PJN_Case__r.MVN_SP_Patient_Id__c,
                PJN_Patient__c,
                PJN_Patient__r.MVN_Patient_Id__c,
                PJN_SP_Patient_Id__c,
                PJN_Status__c,
                PJN_Sub_Status__c,
                PJN_Status_Date__c
            FROM
                PJN_Event__c
            WHERE
                PJN_Case__c IN :carePlans
            AND
                RecordType.DeveloperName = 'MVN_Pharmacy_Status_Update'
        ];
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