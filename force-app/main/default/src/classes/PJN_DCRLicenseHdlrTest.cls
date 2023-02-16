/**
 * Test for PJN_DCRLicenseHdlr trigger handler
 * @author  Mavens
 * @since   May 2020
 */
@IsTest
public with sharing class PJN_DCRLicenseHdlrTest {

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

        insert accounts;
    }

    @IsTest
    static void testInsertLicenseSucessfully() {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = getAccounts();

        List<PJN_License__c> licenses = buildLicenses(accounts);

        Test.startTest();
        insert licenses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines('New');
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs has been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_LICENSE) {
                System.assertNotEquals(null, dcr.PJN_License__c, 'License related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'License DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    @IsTest
    static void testInsertLicenseError() {
        PJN_TestFactoryGlobalSetting.setMock();
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCreateDCRMock.ErrorMock());
        List<Account> accounts = getAccounts();

        List<PJN_License__c> licenses = buildLicenses(accounts);

        Test.startTest();
        insert licenses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines('New');
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs has been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
                System.assertEquals('Required fields are missing: lastname__v', dcr.PJN_Error__c, 'It must get the error message missing field.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_LICENSE) {
                System.assertNotEquals(null, dcr.PJN_License__c, 'License related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'License DCR must always have a Parent DCR related.');
                System.assertEquals('Required fields are missing: lastname__v', dcr.PJN_Error__c, 'It must get the error message missing field.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_CANCELLED, dcr.PJN_Status__c, 'DCR Status must be Cancelled');
            }
        }
    }

    @IsTest
    static void testInsertAndUpdatePendingLicenseSucessfully() {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = getAccounts();

        List<PJN_License__c> licenses = buildLicenses(accounts);
        insert licenses;

        Integer newNPI = 0;
        for (PJN_License__c thisLicense : licenses) {
            newNPI++;
            thisLicense.Name = 'N' + newNPI + thisLicense.Name;
        }

        Test.startTest();
        update licenses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines('New');
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs has been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_LICENSE) {
                System.assertNotEquals(null, dcr.PJN_License__c, 'License related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'License DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_SUBMITTED, dcr.PJN_Status__c, 'DCR Status must be Submitted');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    @IsTest
    static void testUpdateLicenseSucessfully() {
        PJN_TestFactoryGlobalSetting.setMock();
        PJN_NetworkCallout.noRunInTest = true;
        List<Account> accounts = getAccounts();

        for (Account thisAccount : accounts) {
            thisAccount.LastName = 'NewTestValue';
            thisAccount.PJN_Veeva_Network_Id__c = 'VN'+thisAccount.Id;
        }

        update accounts;

        List<PJN_License__c> licenses = buildLicenses(accounts);
        insert licenses;

        delete [SELECT Id FROM PJN_Data_Change_Request__c];

        for (PJN_License__c thisLicense : licenses) {
            thisLicense.PJN_Veeva_Network_Id__c = 'VN'+thisLicense.Id;
            thisLicense.Name = 'New ' + thisLicense.Name;
        }

        Test.startTest();
        PJN_DCR.updateFromNetwork = false;
        update licenses;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PJN_Data_Change_Request__c> dcrs = getDCRsAndLines('Edit');
        System.assert(!dcrs.isEmpty(), 'No DCRs created.');
        System.assertEquals(DATA_SIZE, dcrs.size(), 'No all DCRs has been created.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            if (dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_ACCOUNT) {
                System.assertNotEquals(null, dcr.PJN_Account__c, 'Account related to DCR cannot be null.');
            } else if(dcr.RecordType.DeveloperName == PJN_NetworkConstants.DCR_LICENSE) {
                System.assertNotEquals(null, dcr.PJN_License__c, 'License related to DCR cannot be null.');
                System.assertNotEquals(null, dcr.PJN_Parent_Data_Change_Request__c, 'License DCR must always have a Parent DCR related.');

                System.assertEquals(PJN_NetworkConstants.DCR_STATUS_PENDING, dcr.PJN_Status__c, 'DCR Status must be Pending');
                System.assert(!dcr.PJN_Data_Change_Request_Lines__r.isEmpty(), 'No DCR Lines created.');

                for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_Lines__r) {
                    System.assertNotEquals(null, dcrLine.PJN_New_Value__c, 'DCR New Value cannot be null');
                }
            }
        }
    }

    private static List<PJN_License__c> buildLicenses(List<Account> accounts) {
        List<PJN_License__c> licenses = new List<PJN_License__c>();

        for (Account thisAccount : accounts) {
            licenses.add(
                new PJN_License__c(
                    RecordTypeId = SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get('PJN_DEA_License').getRecordTypeId(),
                    Name = '1234567',
                    PJN_Account__c = thisAccount.Id
                )
            );
        }

        return licenses;
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
                RecordType.DeveloperName = 'PJN_Physician'
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
                PJN_License__c != null
            AND
                PJN_Type__c = :dcrType
        ];
    }
}