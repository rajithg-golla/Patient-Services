/**
 * Test for PJN_NetworkAccountSync
 * @author  Mavens
 * @group   Network
 */
@IsTest
public class PJN_NetworkAccountSyncTest {

    private static final Integer DATA_SIZE = 100;

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkSyncMock.RetrieveHCPSuccessMock());
    }

    @TestSetup
    static void makeData(){
        PJN_TestFactoryGlobalSetting.setMock();

        Test.startTest();
        List<Account> accounts = createAccounts(DATA_SIZE);
        createAddresses(accounts);
        createLicenses(accounts);
        Test.stopTest();
    }

    private static List<Account> createAccounts(Integer numOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer accIndex = 0; accIndex < numOfAccounts; accIndex++) {
            Integer currentAccountNetworkId = 6000 + accIndex;

            accounts.add(
                new Account(
                    FirstName = 'Test' + accIndex,
                    LastName = 'Test' + accIndex,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                    PersonMobilePhone = '555555555555',
                    PJN_Veeva_Network_Id__c = '93358025901211' + currentAccountNetworkId
                )
            );
        }

        insert accounts;

        return accounts;
    }

    private static void createAddresses(List<Account> accounts) {
        List<PJN_Contact_Information__c> address = new List<PJN_Contact_Information__c>();

        Integer currentCount = 6000;

        for (Account thisAccount : accounts) {
            address.add(
                new PJN_Contact_Information__c(
                    PJN_Address_Line_1__c = 'Main Street 123',
                    PJN_Account__c = thisAccount.Id,
                    PJN_Veeva_Network_Id__c = '93358025901200' + currentCount,
                    RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
                )
            );
            currentCount++;
        }

        insert address;
    }

    private static void createLicenses(List<Account> accounts) {
        List<PJN_License__c> licenses = new List<PJN_License__c>();

        Integer currentCount = 6000;

        for (Account thisAccount : accounts) {
            licenses.add(
                new PJN_License__c(
                    Name = '1234567',
                    PJN_Type__c = 'NPI',
                    PJN_Account__c = thisAccount.Id,
                    PJN_Veeva_Network_Id__c = '93291072424496' + currentCount
                )
            );
            currentCount++;
        }

        insert licenses;
    }

    @IsTest
    static void testIfHCPisSynced() {
        PJN_TestFactoryGlobalSetting.setMock();
        Account currentAccount = [
            SELECT
                Id
            FROM
                Account
            WHERE
                RecordType.DeveloperName = 'PJN_Physician'
            LIMIT
                1
        ];

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        isUpdated = PJN_NetworkAccountSync.syncAccount(currentAccount.Id, null);
        Test.stopTest();

        System.assert(isUpdated, 'Account is not updated.');

       List<Account> hcps = getHCPs();

       for (Account hcp : hcps) {
            System.assertEquals('Daniel', hcp.FirstName, 'HCP first name must be Daniel.');
            System.assertEquals('Carter', hcp.LastName, 'HCP last name must be Carter.');

            for (PJN_Contact_Information__c thisAddress : hcp.PJN_Contact_Information__r) {
                System.assertEquals('200 Park Blvd.', thisAddress.PJN_Address_Line_1__c, 'HCP Address line 1 must be 200 Park Blvd.');
            }

            for (PJN_License__c thisLicense : hcp.PJN_Licenses__r) {
                System.assertEquals('1256987', thisLicense.Name, 'HCP license must be 1256987.');
            }
       }
    }

    @IsTest
    static void testIfContactInformationAndHCPisSynced() {
        PJN_TestFactoryGlobalSetting.setMock();
        PJN_Contact_Information__c currentCI = [
            SELECT
                Id
            FROM
                PJN_Contact_Information__c
            WHERE
                RecordType.DeveloperName = 'PJN_Address'
            LIMIT
                1
        ];

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        isUpdated = PJN_NetworkAccountSync.syncAccount(currentCI.Id, 'PJN_Account__c');
        Test.stopTest();

        System.assert(isUpdated, 'Account is not updated.');

       List<Account> hcps = getHCPs();

       for (Account hcp : hcps) {
            System.assertEquals('Daniel', hcp.FirstName, 'HCP first name must be Daniel.');
            System.assertEquals('Carter', hcp.LastName, 'HCP last name must be Carter.');

            for (PJN_Contact_Information__c thisAddress : hcp.PJN_Contact_Information__r) {
                System.assertEquals('200 Park Blvd.', thisAddress.PJN_Address_Line_1__c, 'HCP Address line 1 must be 200 Park Blvd.');
            }

            for (PJN_License__c thisLicense : hcp.PJN_Licenses__r) {
                System.assertEquals('1256987', thisLicense.Name, 'HCP license must be 1256987.');
            }
       }
    }

    @IsTest
    static void testIfLicenseAndHCPisSynced() {
        PJN_TestFactoryGlobalSetting.setMock();
        PJN_License__c currentLicense = [
            SELECT
                Id
            FROM
                PJN_License__c
            LIMIT
                1
        ];

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        isUpdated = PJN_NetworkAccountSync.syncAccount(currentLicense.Id, 'PJN_Account__c');
        Test.stopTest();

        System.assert(isUpdated, 'Account is not updated.');

       List<Account> hcps = getHCPs();

       for (Account hcp : hcps) {
            System.assertEquals('Daniel', hcp.FirstName, 'HCP first name must be Daniel.');
            System.assertEquals('Carter', hcp.LastName, 'HCP last name must be Carter.');

            for (PJN_Contact_Information__c thisAddress : hcp.PJN_Contact_Information__r) {
                System.assertEquals('200 Park Blvd.', thisAddress.PJN_Address_Line_1__c, 'HCP Address line 1 must be 200 Park Blvd.');
            }

            for (PJN_License__c thisLicense : hcp.PJN_Licenses__r) {
                System.assertEquals('1256987', thisLicense.Name, 'HCP license must be 1256987.');
            }
       }
    }

    @IsTest
    static void testIfDCRisSynced() {
        PJN_TestFactoryGlobalSetting.setMock();
        List<PJN_Data_Change_Request__c> dcrs = [
            SELECT
                Id,
                PJN_Status__c,
                PJN_DCR_External_ID__c,
                PJN_Veeva_Network_Id__c,
                PJN_Parent_Data_Change_Request__c
            FROM
                PJN_Data_Change_Request__c
        ];

        System.assert(!dcrs.isEmpty(), 'No DCR found.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_SUBMITTED;
            dcr.PJN_DCR_External_ID__c = dcr.Id;
            dcr.PJN_Veeva_Network_Id__c = String.isNotBlank(dcr.PJN_Parent_Data_Change_Request__c) ? dcr.PJN_Parent_Data_Change_Request__c + 'ADDRESS' : dcr.Id;
        }

        update dcrs;

        dcrs = [
            SELECT
                Id,
                PJN_Account__c
            FROM
                PJN_Data_Change_Request__c
            WHERE
                PJN_Account__c != null
            AND
                PJN_Status__c = :PJN_NetworkConstants.DCR_STATUS_SUBMITTED
            AND
                PJN_DCR_External_ID__c != null
        ];

        System.assert(!dcrs.isEmpty(), 'No Submitted DCR found.');

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        isUpdated = PJN_NetworkAccountSync.syncAccount(dcrs[0].PJN_Account__c, null);
        Test.stopTest();

        System.assert(isUpdated, 'DCR is not updated.');
    }

    private static List<Account> getHCPs() {
        return [
            SELECT
                Id,
                FirstName,
                LastName,
                (
                    SELECT
                        Id,
                        PJN_Address_Line_1__c
                    FROM
                        PJN_Contact_Information__r
                ),
                (
                    SELECT
                        Id,
                        Name
                    FROM
                        PJN_Licenses__r
                )
            FROM
                Account
            WHERE
                RecordType.DeveloperName = 'PJN_Physician'
            AND
                PJN_Veeva_Network_Id__c != null
        ];
    }
}