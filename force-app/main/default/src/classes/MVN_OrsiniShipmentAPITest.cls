@IsTest
private class MVN_OrsiniShipmentAPITest {

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
                    FirstName = 'Orsini Patient',
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
        Integer currentSPPatientId = 123123000;
        for (Account patient : patients) {
            carePlans.add(
                new Case (
                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                    AccountId = patient.Id,
                    MVN_SP_Patient_Id__c = String.valueOf(currentSPPatientId),
                    PJN_Program__c = careProgram.Id,
                    Status = 'Open'
                )
            );
            currentSPPatientId++;
        }
        insert carePlans;
    }

    @IsTest
    static void testIfSPShipmentWorksCorrectly() {
        List<Case> carePlans = getCarePlans();
        buildRequestContext(carePlans, true);
        MVN_OrsiniShipmentResponse orsiniShipmentResponse;
        Test.startTest();
        orsiniShipmentResponse = MVN_OrsiniShipmentAPI.handleOrsiniShipmentPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniShipmentResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('success', orsiniShipmentResponse.status, 'Orsini Shipment API must succeed. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniShipmentResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniShipmentResponse.shipments, 'shipments cannot be null. Error: ' + transactionLogError);
        System.assert(!orsiniShipmentResponse.shipments.isEmpty(), 'shipments cannot be empty. Error: ' + transactionLogError);
        for (MVN_OrsiniShipmentResult shipmentResult : orsiniShipmentResponse.shipments) {
            System.assert(shipmentResult.success, 'Shipment must succeed. Error: ' + transactionLogError);
            System.assertEquals(null, shipmentResult.message, 'Shipment message must be null. Error: ' + transactionLogError);
        }
        List<PJN_Shipment__c> shipments = getShipments(carePlans);
        System.assertEquals(carePlans.size(), shipments.size(), 'Shipments must match number of CarePlans. Error: ' + transactionLogError);
        for (PJN_Shipment__c shipment : shipments) {
            System.assertNotEquals(null, shipment.PJN_Patient__c, 'Patient Id cannot be null. Error: ' + transactionLogError);
            System.assertNotEquals(null, shipment.PJN_Care_Plan__c, 'CarePlan Id cannot be null. Error: ' + transactionLogError);
            System.assertNotEquals(null, shipment.PJN_SP_Patient_ID__c, 'SP Patient Id cannot be null. Error: ' + transactionLogError);
            System.assertEquals('COM', shipment.PJN_Dispense_Type__c, 'Dispense must be COM. Error: ' + transactionLogError);
            System.assertEquals(System.today(), shipment.PJN_Date_Shipped__c, 'Date shipped must be today. Error: ' + transactionLogError);
            System.assertEquals(System.today().addMonths(1), shipment.MVN_Next_Fill_Date__c, 'Next Fill Date date must be in a month. Error: ' + transactionLogError);
            System.assertEquals('ndc', shipment.PJN_NDC__c, 'NDC must be ndc value. Error: ' + transactionLogError);
            System.assertEquals('product description', shipment.PJN_Product_Description__c, 'Shipment must have a product description.');
            System.assertEquals(12, shipment.PJN_Quantity_Dispensed__c, 'Shipment must have a quantity dispensed. Error: ' + transactionLogError);
        }
    }

    @IsTest
    static void testIfSPShipmentWorksNoEvent() {
        List<Case> carePlans = new List<Case>();
        buildRequestContext(carePlans, true);
        MVN_OrsiniShipmentResponse orsiniShipmentResponse;
        Test.startTest();
        orsiniShipmentResponse = MVN_OrsiniShipmentAPI.handleOrsiniShipmentPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniShipmentResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('error', orsiniShipmentResponse.status, 'Orsini Shipment API must error. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniShipmentResponse.message, 'No message in the response. Error: ' + transactionLogError);
        System.assertEquals(null, orsiniShipmentResponse.shipments, 'shipments must be null. Error: ' + transactionLogError);
    }

    @IsTest
    static void testIfSPShipmentWorksWrong() {
        List<Case> carePlans = getCarePlans();
        buildRequestContext(carePlans, false);
        MVN_OrsiniShipmentResponse orsiniShipmentResponse;
        Test.startTest();
        orsiniShipmentResponse = MVN_OrsiniShipmentAPI.handleOrsiniShipmentPostAPI();
        Test.stopTest();
        String transactionLogError = getTransactionLogError();
        System.assertNotEquals(null, orsiniShipmentResponse, 'Response cannot be null. Error: ' + transactionLogError);
        System.assertEquals('error', orsiniShipmentResponse.status, 'Orsini Shipment API must error. Error: ' + transactionLogError);
        System.assertNotEquals(null, orsiniShipmentResponse.shipments, 'shipments cannot be null. Error: ' + transactionLogError);
        System.assert(!orsiniShipmentResponse.shipments.isEmpty(), 'shipments cannot be empty. Error: ' + transactionLogError);
        Boolean oneIsSuccess = false;
        for (MVN_OrsinishipmentResult shipmentResult : orsiniShipmentResponse.shipments) {
            System.assert(!shipmentResult.success || !oneIsSuccess, 'Shipment must be wrong. Error: ' + transactionLogError);
            System.assert(shipmentResult.message != null || !oneIsSuccess, 'Shipment message must be null. Error: ' + transactionLogError);
            oneIsSuccess = oneIsSuccess || shipmentResult.success;
        }
        List<PJN_Shipment__c> shipments = getShipments(carePlans);
        System.assertEquals(1, shipments.size(), 'Only one Shipment should be created. Error: ' + transactionLogError);
    }

    private static List<Case> getCarePlans() {
        return [
            SELECT
                Id,
                MVN_SP_Patient_Id__c
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
        List<MVN_OrsiniShipmentRequest> requests = new List<MVN_OrsiniShipmentRequest>();
        Boolean oneAtLeast = false;
        List<Id> returningCarePlanIds = new List<Id>();
        for (Case carePlan : carePlans) {
            MVN_OrsiniShipmentRequest request = new MVN_OrsiniShipmentRequest();
            request.unique_id = carePlan.MVN_SP_Patient_Id__c;
            request.sp_patient_id = hasPatientId || !oneAtLeast ? carePlan.MVN_SP_Patient_Id__c : '99999999';
            request.dispense_type = 'COM';
            request.dispense_date = System.today();
            request.next_fill_date = System.today().addMonths(1);
            request.ndc = 'ndc';
            request.product_description = 'product description';
            request.quantity_dispensed = 12;
            requests.add(request);
            if (hasPatientId || !oneAtLeast) {
                returningCarePlanIds.add(carePlan.Id);
            }
            Test.setFixedSearchResults(returningCarePlanIds);
            oneAtLeast = true;
        }
        return System.JSON.serializePretty(requests);
    }

    private static List<PJN_Shipment__c> getShipments(List<Case> carePlans) {
        return [
            SELECT
                Id,
                PJN_Care_Plan__c,
                PJN_Care_Plan__r.MVN_SP_Patient_Id__c,
                PJN_Patient__c,
                PJN_SP_Patient_ID__c,
                PJN_Dispense_Type__c,
                PJN_Date_Shipped__c,
                MVN_Next_Fill_Date__c,
                PJN_NDC__c,
                PJN_Product_Description__c,
                PJN_Quantity_Dispensed__c
            FROM
                PJN_Shipment__c
            WHERE
                PJN_Care_Plan__c IN :carePlans
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