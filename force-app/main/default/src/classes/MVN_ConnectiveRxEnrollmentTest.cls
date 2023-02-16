/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Test for MVN_ConnectiveRxEnrollment
 */
@IsTest
public with sharing class MVN_ConnectiveRxEnrollmentTest {

    private static List<Account> accounts;
    private static Account patient;
    private static Account physician;
    private static Account caregiver;
    private static Account payer;

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
        createFulfillment(carePlan);
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
        PJN_Assistance_Program__c assistanceProgram = new PJN_Assistance_Program__c(
            RecordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Copay').getRecordTypeId(),
            PJN_Care_Plan__c = carePlan.Id
        );
        insert assistanceProgram;
        PJN_Fulfillment_Request__c fulfillment = new PJN_Fulfillment_Request__c (
            PJN_Care_Plan__c = carePlan.Id,
            RecordTypeId = Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Enrollment').getRecordTypeId(),
            MVN_Copay_Assistance_Program__c = assistanceProgram.Id
        );
        insert fulfillment;
        return fulfillment;
    }

    @IsTest
    static void testIfFulfillmentWasSentCorrectly() {
        Test.setMock(HttpCalloutMock.class, new MVN_ConnectiveRxEnrollmentMock.SuccessMock());
        PJN_Fulfillment_Request__c fulfillment = getFulfillment();
        Map<String, Object> result = new Map<String, Object>();
        result.put('success', false);
        Test.startTest();
        result = MVN_ConnectiveRxEnrollment.sendEnrollment(fulfillment.Id);
        Test.stopTest();
        PJN_Transaction_Log_Object__c transactionLog = getTransactionLog();
        String transactionLogMessage = transactionLog != null ? transactionLog.PJN_Message__c : '';
        System.assert(Boolean.valueOf(result.get('success')), 'Fulfillment has not been sent correctly. ' + transactionLogMessage);
        PJN_Assistance_Program__c assistanceProgram = getAssistanceProgram(fulfillment.PJN_Care_Plan__c);
        System.assertEquals('07c3e2f4-d726-4e55-b860-2b4ab9243535', assistanceProgram.MVN_Copay_Enrollment_Id__c, 'Wrong Copay Enrollment Id in Assistance Program');
        System.assertEquals('accepted', assistanceProgram.MVN_Copay_Status__c, 'Wrong Copay Status in Assistance Program');
        System.assert(!assistanceProgram.MVN_Copay_Is_Reenrollment__c, 'Wrong Copay Is Enrollment in Assistance Program');
        System.assertEquals('07c3e2f4-d726-4e55-b860-2b4ab9243535', assistanceProgram.MVN_Copay_Patient_Id__c, 'Wrong Copay Patient Id in Assistance Program');
        System.assertEquals('07c3e2f4-d726-4e55-b860-2b4ab9243535', assistanceProgram.MVN_Copay_Caregiver_Id__c, 'Wrong Copay Caregiver Id in Assistance Program');
        System.assertEquals('EC123456789', assistanceProgram.MVN_Copay_Group_Number__c, 'Wrong Copay Group Number in Assistance Program');
        System.assertEquals('1234567890', assistanceProgram.MVN_Copay_Member_Id__c, 'Wrong Copay Member Id in Assistance Program');
        System.assertEquals('019158', assistanceProgram.MVN_Copay_BIN__c, 'Wrong Copay BIN in Assistance Program');
        System.assertEquals('CNRX', assistanceProgram.MVN_Copay_PCN__c, 'Wrong Copay PCN in Assistance Program');
        System.assert(assistanceProgram.MVN_Copay_Is_Activated__c, 'Wrong Copay Is Activated in Assistance Program');
    }

    @IsTest
    static void testIfFulfillmentWasIncorrectlySent() {
        Test.setMock(HttpCalloutMock.class, new MVN_ConnectiveRxEnrollmentMock.ValidationErrorMock());
        PJN_Fulfillment_Request__c fulfillment = getFulfillment();
        Map<String, Object> result = new Map<String, Object>();
        result.put('success', false);
        Test.startTest();
        result = MVN_ConnectiveRxEnrollment.sendEnrollment(fulfillment.Id);
        Test.stopTest();
        System.assert(!Boolean.valueOf(result.get('success')), 'Fulfillment cannot be sent correctly.');
        PJN_Transaction_Log_Object__c transactionLog = getTransactionLog();
        System.assertNotEquals(null, transactionLog, 'Transaction log must be created.');
        System.assertEquals('error', transactionLog.PJN_Level__c.toLowerCase(), 'Transaction log must be an error.');
        System.assert(transactionLog.PJN_Callout_Response__c.toLowerCase().contains('bad request'), 'Transaction log must be bad request.');
    }

    private static PJN_Fulfillment_Request__c getFulfillment() {
        return [
            SELECT
                Id,
                PJN_Care_Plan__c
            FROM
                PJN_Fulfillment_Request__c
            LIMIT 1
        ];
    }

    private static PJN_Transaction_Log_Object__c getTransactionLog() {
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
        if (transactionLogs.isEmpty()) {
            return null;
        }
        return transactionLogs[0];
    }

    private static PJN_Assistance_Program__c getAssistanceProgram(Id carePlanId) {
        return [
            SELECT
                Id,
                MVN_Copay_Enrollment_Id__c,
                MVN_Copay_Status__c,
                MVN_Copay_Is_Reenrollment__c,
                MVN_Copay_Patient_Id__c,
                MVN_Copay_Caregiver_Id__c,
                MVN_Copay_Group_Number__c,
                MVN_Copay_Member_Id__c,
                MVN_Copay_BIN__c,
                MVN_Copay_PCN__c,
                MVN_Copay_Is_Activated__c,
                MVN_Copay_Issued_Date__c,
                MVN_Copay_Effective_Date__c,
                MVN_Copay_Activated_Date__c,
                MVN_Copay_Expiration_Date__c,
                MVN_Copay_Deactivated_Date__c,
                MVN_Copay_Program_Cap__c,
                MVN_Copay_Total_Uses__c,
                MVN_Copay_Usage_Period__c,
                MVN_Copay_Usage_Period_Unit__c,
                MVN_Copay_Is_Active__c,
                MVN_Copay_Eligibility_Check_Type__c,
                MVN_Copay_Enrollment_Success__c,
                MVN_Copay_Enrollment_Result_Details__c
            FROM
                PJN_Assistance_Program__c
            WHERE
                PJN_Care_Plan__c = :carePlanId
            AND
                RecordType.DeveloperName = 'PJN_Copay'
        ];
    }
}