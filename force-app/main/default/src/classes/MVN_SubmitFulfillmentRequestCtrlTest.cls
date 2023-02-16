/**
 * @author      Mavens
 * @group       Fulfillment
 * @description Test for PJN_SubmitFulfillmentRequestCtrl
 */
@IsTest
private class MVN_SubmitFulfillmentRequestCtrlTest {


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
            FirstName = 'Patient',
            LastName = 'Test',
            MVN_Birthdate__c = Date.valueOf('1988-12-06'),
            HealthCloudGA__Gender__pc = 'Male',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        return patient;
    }

    private static Account buildPhysician() {
        Account physician = new Account (
            FirstName = 'Physician',
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
            RecordTypeId = Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName().get('PJN_SP_Triage').getRecordTypeId(),
            PJN_Fulfillment_Request_Status__c = 'Pending',
            PJN_Patient__c = carePlan.AccountId,
            PJN_Physician__c = carePlan.PJN_Physician__c,
            MVN_Patient_Id__c = carePlan.AccountId,
            PJN_Patient_First_Name__c = 'Patient',
            PJN_Patient_Last_Name__c = 'Test',
            PJN_Patient_DOB__c = Date.valueOf('1988-12-06'),
            PJN_Patient_Gender__c = 'Male',
            PJN_Patient_Address_Line_1__c = '123 Main Street',
            PJN_Patient_City__c = 'Chicago',
            PJN_Patient_State__c = 'IL',
            PJN_Patient_Postal_Code__c = '60606',
            PJN_Patient_Phone__c = '111111111',
            MVN_ICD_10_CM_Diagnosis_Code__c = '12343565476',
            PJN_Physician_First_Name__c = 'Physician',
            PJN_Physician_Last_Name__c = 'Test',
            PJN_Physician_Address_Line_1__c = '122 Main Street',
            PJN_Physician_City__c = 'Chicago',
            PJN_Physician_State__c = 'IL',
            PJN_Physician_Postal_Code__c = '60606',
            PJN_Physician_NPI__c = '1234567890',
            PJN_Date_of_Rx__c = Date.valueOf('2021-7-06'),
            PJN_NDC__c = '9087654321',
            MVN_Patient_Diagnosis__c = 'Test Diagnosis',
            PJN_HIPPA_Consent_Status__c = 'Status',
            MVN_Program_Consent_Status__c = 'Status',
            MVN_PAP_Consent_Status__c = 'Status'
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
    static void testIfSubmitFulfillmentRequestCorrectly() {
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest(null);
        Boolean response;
        Test.startTest();
        response = PJN_SubmitFulfillmentRequestCtrl.submitFulfillmentRecord(fulfillment.Id);
        Test.stopTest();
        System.assert(response, 'Submit method went wrong');
        fulfillment = getFulfillmentRequest(fulfillment.Id);
        System.assertEquals(Label.MVN_Orsini_Patient_Status_Submitted, fulfillment.PJN_Fulfillment_Request_Status__c, 'Fulfillment must be Submitted');
    }

    @IsTest
    static void testIfSubmitFulfillmentRequestWrong() {
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest(null);
        fulfillment.PJN_NDC__c = null;
        update fulfillment;
        Boolean response = false;
        String message;
        Test.startTest();
        try {
            response = PJN_SubmitFulfillmentRequestCtrl.submitFulfillmentRecord(fulfillment.Id);
        } catch(Exception ex) {
            message = ex.getMessage();
        }
        Test.stopTest();
        System.assert(!response, 'Submit method must go wrong');
        System.assert(String.IsNotBlank(message), 'it should have an error message');
        String errorMessageStartsWith = String.format(Label.MVN_Missing_Required_Fields_Submitting_Fulfillment_Error_Message, new List<String> {''});
        System.assert(message.startsWith(errorMessageStartsWith), 'Error message is incorrect: ' + message);
    }

    private static PJN_Fulfillment_Request__c getFulfillmentRequest(Id fulfillmentId) {
        Map<String, Schema.SObjectField> sobjectFields = Schema.SObjectType.PJN_Fulfillment_Request__c.fields.getMap();
        String fieldNames = '';
        for(String fieldName : sobjectFields.keySet()) {
            fieldNames += fieldName + ',';
        }
        fieldNames = fieldNames.substringBeforeLast(',');
        String whereStatement = String.isNotBlank(fulfillmentId) ?
            'Id = :fulfillmentId' :
            'RecordType.DeveloperName = \'PJN_SP_Triage\'';
        String query = 'SELECT ' + fieldNames + ' FROM PJN_Fulfillment_Request__c WHERE ' + whereStatement + ' LIMIT 1';
        return (PJN_Fulfillment_Request__c) Database.query(query);
    }
}