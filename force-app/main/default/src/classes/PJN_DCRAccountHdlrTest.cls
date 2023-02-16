/**
 * Test for PJN_DCRAccountHdlr trigger handler
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_DCRAccountHdlrTest {

    private static final Integer DATA_SIZE = 49;

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.SuccessMock());

        PJN_NetworkCallout.noRunInTest = false;
    }

    @IsTest
    static void testInsertAccountSucessfully(){
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = buildAccounts(DATA_SIZE);

        Test.startTest();
        insert accounts;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted');
            System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

            for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                System.assertEquals(null, dcrLine.PJN_Old_Value__c, 'DCR Old Value must be null, because it is a new record.');
                System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null.');
            }
        }
    }

    @IsTest
    static void testInsertAccountError(){
        PJN_TestFactoryGlobalSetting.setMock();
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCreateDCRMock.ErrorMock());
        List<Account> accounts = buildAccounts(DATA_SIZE);

        Test.startTest();
        insert accounts;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            System.assertEquals(PJN_NetworkConstants.DCR_STATUS_CANCELLED, dcr.PJN_Status__c, 'DCR Status must be Cancelled.');
            System.assertEquals('Required fields are missing: lastname__v', dcr.PJN_Error__c, 'It must get the error message missing field.');
        }
    }

    @IsTest
    static void testInsertAndUpdatePendingAccountSucessfully(){
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = buildAccounts(DATA_SIZE);
        insert accounts;

        delete [SELECT Id FROM PJN_Data_Change_Request__c];

        for (Account thisAccount : accounts) {
            thisAccount.LastName = 'NewTestValue';
        }

        Test.startTest();
        update accounts;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_EDIT);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted.');
            System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

            for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                System.assertNotEquals(null, dcrLine.PJN_Old_Value__c, 'DCR Old Value cannot be null. FieldName: ' + dcrLine.PJN_Field_API_Name__c);
                System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null. FieldName: ' + dcrLine.PJN_Field_API_Name__c);
            }
        }
    }

    @IsTest
    static void testUpdateAccountSucessfully(){
        PJN_TestFactoryGlobalSetting.setMock();
        PJN_NetworkCallout.noRunInTest = true;
        List<Account> accounts = buildAccounts(DATA_SIZE);

        insert accounts;

        for (Account thisAccount : accounts) {
            thisAccount.LastName = 'NewTestValue';
            thisAccount.PJN_Veeva_Network_Id__c = 'VN'+thisAccount.FirstName;
        }

        delete [SELECT Id FROM PJN_Data_Change_Request__c WHERE PJN_Account__c IN :accounts];

        Test.startTest();
        update accounts;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_EDIT);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'Not all DCRs have been created successfully.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            System.assertEquals(PJN_NetworkConstants.DCR_STATUS_PENDING, dcr.PJN_Status__c, 'DCR Status must be Pending.');
            System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

            for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                System.assertNotEquals(null, dcrLine.PJN_Old_Value__c, 'DCR Old Value cannot be null, because it is a record edited.');
                System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
            }
        }
    }

    @isTest
    private static void testUpdateDCRsWithError() {
        PJN_NetworkCallout.noRunInTest = true;
        List<Account> accounts = buildAccounts(DATA_SIZE);
        insert accounts;
        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_NEW);
        Map<Id, String> errorMessageByDCRId = new Map<Id, String>();
        for(PJN_Data_Change_Request__c thisDCR : dcrs) {
            errorMessageByDCRId.put(thisDCR.Id, 'Error: ' + thisDCR.Id);
        }
        PJN_DCRAccountHdlr dCRAccountHdlr = new PJN_DCRAccountHdlr();

        Test.startTest();
            dCRAccountHdlr.updateDCRsWithError(dcrs, errorMessageByDCRId);
        Test.stopTest();

        List<PJN_Data_Change_Request__c> actualDcrs = getDCRsAndLines(accounts, PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assertEquals(dcrs.size(), actualDcrs.size(), 'DCRs do not match.');
    }

    private static List<Account> buildAccounts(Integer numOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer accIndex = 0; accIndex < numOfAccounts; accIndex++) {
            accounts.add(
                new Account(
                    FirstName = 'Test' + accIndex,
                    LastName = 'Test' + accIndex,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                    PersonMobilePhone = '555555555555'
                )
            );
        }

        return accounts;
    }

    private static List<PJN_Data_Change_Request__c> getDCRsAndLines(List<Account> accounts, String dcrType) {
        return [
            SELECT
                Id,
                Name,
                RecordTypeId,
                PJN_Status__c,
                PJN_Account__c,
                PJN_Contact_Information__c,
                PJN_License__c,
                PJN_Veeva_Network_Id__c,
                PJN_External_Id__c,
                PJN_Type__c,
                PJN_Error__c,
                PJN_Record_Type_Name__c,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
            WHERE
                PJN_Account__c IN :accounts
            AND
                PJN_Type__c = :dcrType
        ];
    }
}