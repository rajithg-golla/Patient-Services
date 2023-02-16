/**
 * Test for PJN_DCRAddressHdlr trigger handler
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_DCRAddressHdlrTest {

    private static final Integer DATA_SIZE = 49;

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.SuccessMock());

        PJN_NetworkCallout.noRunInTest = false;
    }

    @TestSetup
    static void makeData(){
        PJN_TestFactoryGlobalSetting.setMock();

        PJN_NetworkCallout.noRunInTest = true;
        Test.startTest();
        createAccounts(DATA_SIZE);

        Test.getEventBus().deliver();
        Test.stopTest();
        PJN_NetworkCallout.noRunInTest = false;

        delete [SELECT Id FROM PJN_Data_Change_Request__c];
    }

    private static void createAccounts(Integer numOfAccounts) {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = new List<Account>();

        for (Integer accIndex = 0; accIndex < numOfAccounts; accIndex++) {
            accounts.add(
                new Account(
                    Name = 'Test' + accIndex,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId()
                )
            );
        }

        insert accounts;
    }

    @IsTest
    static void testInsertAddressSucessfully(){
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = getAccounts();

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);

        Test.startTest();
        insert addresses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');

        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ADDRESS) {
                System.assertNotEquals(null, dcr.PJN_Contact_Information__c, 'Address related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'Address DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    @IsTest
    static void testInsertAddressError() {
        PJN_TestFactoryGlobalSetting.setMock();
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCreateDCRMock.ErrorMock());
        List<Account> accounts = getAccounts();

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);

        Test.startTest();
        insert addresses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
                System.assertEquals('Required fields are missing: lastname__v', dcr.PJN_Error__c, 'It must get the error message missing field.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ADDRESS) {
                System.assertNotEquals(null, dcr.PJN_Contact_Information__c, 'Address related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'Address DCR must always have a Parent DCR related.');
                System.assertEquals('Required fields are missing: lastname__v', dcr.PJN_Error__c, 'It must get the error message missing field.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_CANCELLED, dcr.PJN_Status__c, 'DCR Status must be Cancelled');
            }
        }
    }

    @IsTest
    static void testInsertAndUpdatePendingAddressSucessfully() {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = getAccounts();

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);
        insert addresses;

        for (PJN_Contact_Information__c thisAddress : addresses) {
            thisAddress.PJN_Address_Line_1__c = 'New ' + thisAddress.PJN_Address_Line_1__c;
        }

        Test.startTest();
        update addresses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(PJN_NetworkConstants.DCR_TYPE_NEW);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.' + [
            SELECT
                Count(Id),
                PJN_Type__c
            FROM
                PJN_Data_Change_Request__c
            WHERE PJN_Account__c != null
            GROUP BY PJN_Type__c
        ]);

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ADDRESS) {
                System.assertNotEquals(null, dcr.PJN_Contact_Information__c, 'Address related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'Address DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    @IsTest
    static void testUpdateAddressSucessfully() {
        PJN_TestFactoryGlobalSetting.setMock();
        PJN_NetworkCallout.noRunInTest = true;
        List<Account> accounts = getAccounts();

        for (Account thisAccount : accounts) {
            thisAccount.Name = 'NewTestValue';
            thisAccount.PJN_Veeva_Network_Id__c = 'VN'+thisAccount.Id;
        }

        PJN_DCR.updateFromNetwork = false;
        update accounts;

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);
        PJN_DCR.updateFromNetwork = false;
        insert addresses;

        for (PJN_Contact_Information__c thisAddress : addresses) {
            thisAddress.PJN_Veeva_Network_Id__c = 'VN'+thisAddress.Id;
            thisAddress.PJN_Address_Line_1__c = 'New ' + thisAddress.PJN_Address_Line_1__c;
        }

        PJN_DCR.updateFromNetwork = false;
        delete [SELECT Id FROM PJN_Data_Change_Request__c];

        Test.startTest();
        PJN_DCR.updateFromNetwork = false;
        update addresses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines(PJN_NetworkConstants.DCR_TYPE_EDIT);
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs have been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ADDRESS) {
                System.assertNotEquals(null, dcr.PJN_Contact_Information__c, 'Address related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'Address DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_PENDING, dcr.PJN_Status__c, 'DCR Status must be Pending');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    private static List<PJN_Contact_Information__c> buildAddresses(List<Account> accounts) {
        List<PJN_Contact_Information__c> address = new List<PJN_Contact_Information__c>();

        for (Account thisAccount : accounts) {
            address.add(
                new PJN_Contact_Information__c(
                    PJN_Address_Line_1__c = 'Main Street 123',
                    PJN_City__c = 'Chicago',
                    PJN_State__c = 'IL',
                    PJN_Address_Line_2__c = '3rd floor',
                    PJN_Account__c = thisAccount.Id,
                    RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
                )
            );
        }

        return address;
    }

    private static List<Account> getAccounts() {
        return [
            SELECT
                Id,
                FirstName,
                LastName,
                PersonMobilePhone,
                PJN_Veeva_Network_Id__c
            FROM
                Account
            WHERE
                RecordType.DeveloperName = 'PJN_Organization'
        ];
    }

    private static List<PJN_Data_Change_Request__c> getDCRsAndLines(String dcrType) {
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
                RecordType.DeveloperName,
                PJN_Parent_Data_Change_Request__c,
                PJN_Error__c,
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
                PJN_Contact_Information__c != null
            AND
                PJN_Type__c = :dcrType
        ];
    }
}