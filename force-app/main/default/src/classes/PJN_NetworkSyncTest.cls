/**
 * Test for PJN_NetworkSync
 * @author  Mavens
 * @group   Network
 */
@IsTest
public class PJN_NetworkSyncTest {

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
    }

    @TestSetup
    static void makeData(){
        PJN_TestFactoryGlobalSetting.setMock();

        Test.startTest();
        List<Account> accounts = new List<Account>();

        accounts.add(
            new Account (
                FirstName = 'whatever',
                LastName = 'whatever',
                PJN_Veeva_Network_Id__c = '933580259012116000',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId()
            )
        );

        accounts.add(
            new Account (
                Name = 'Hospital',
                PJN_Veeva_Network_Id__c = '27112020000000001',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId()
            )
        );

        insert accounts;
        Test.stopTest();
    }

    @IsTest
    static void testAccountCreatingAddressAndLicense() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkSyncMock.RetrieveHCPSuccessMock());
        PJN_TestFactoryGlobalSetting.setMock();
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'PJN_Physician' LIMIT 1];

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        PJN_NetworkSync networkSync = new PJN_NetworkSync(acc.Id);
        isUpdated = networkSync.sync();
        Test.stopTest();

        System.assert(isUpdated, 'Sync process did not updated the records');

        acc = getAccount(acc.Id);
        System.assertEquals('Daniel', acc.FirstName, 'Sync process did not update first name');
        System.assertEquals('Carter', acc.LastName, 'Sync process did not update last name');

        System.assert(!acc.PJN_Contact_Information__r.isEmpty(), 'Sync process did not create address');
        System.assertEquals('200 Park Blvd.', acc.PJN_Contact_Information__r[0].PJN_Address_Line_1__c, 'Sync process did not create address line 1');

        System.assert(!acc.PJN_Licenses__r.isEmpty(), 'Sync process did not create license');
        System.assertEquals('1256987', acc.PJN_Licenses__r[0].Name, 'Sync process did not create license number');

        System.assert(!acc.Affiliation__r.isEmpty(), 'Sync process did not create affiliation');
        System.assertEquals(1, acc.Affiliation__r.size(), 'Sync process must not create affiliations for non-existing HCOs');
        System.assertEquals('27112020000000001', acc.Affiliation__r[0].PJN_Parent_Account__r.PJN_Veeva_Network_Id__c, 'Sync process did not create affiliation');
    }

    @IsTest
    static void testAccountUpdatingAddressAndLicense() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkSyncMock.RetrieveHCPSuccessMock());
        PJN_TestFactoryGlobalSetting.setMock();
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'PJN_Physician' LIMIT 1];

        createAddress(acc.Id);
        createLicense(acc.Id);

        Boolean isUpdated = false;

        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        PJN_NetworkSync networkSync = new PJN_NetworkSync(acc.Id);
        isUpdated = networkSync.sync();
        Test.stopTest();

        System.assert(isUpdated, 'Sync process did not updated the records');

        acc = getAccount(acc.Id);
        System.assertEquals('Daniel', acc.FirstName, 'Sync process did not update first name');
        System.assertEquals('Carter', acc.LastName, 'Sync process did not update last name');

        System.assert(!acc.PJN_Contact_Information__r.isEmpty(), 'Sync process did not create address');
        System.assertEquals('200 Park Blvd.', acc.PJN_Contact_Information__r[0].PJN_Address_Line_1__c, 'Sync process did not create address line 1');

        System.assert(!acc.PJN_Licenses__r.isEmpty(), 'Sync process did not create license');
        System.assertEquals('1256987', acc.PJN_Licenses__r[0].Name, 'Sync process did not create license number');

        System.assert(!acc.Affiliation__r.isEmpty(), 'Sync process did not create affiliation');
        System.assertEquals(1, acc.Affiliation__r.size(), 'Sync process must not create affiliations for non-existing HCOs');
        System.assertEquals('27112020000000001', acc.Affiliation__r[0].PJN_Parent_Account__r.PJN_Veeva_Network_Id__c, 'Sync process did not create affiliation');
    }

    private static Account getAccount(Id accountId) {
        return [
            SELECT
                Id,
                FirstName,
                LastName,
                (
                    SELECT
                        Id,
                        PJN_Address_Line_1__c,
                        PJN_Address_Line_2__c,
                        PJN_City__c,
                        PJN_State__c
                    FROM
                        PJN_Contact_Information__r
                ),
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Type__c
                    FROM
                        PJN_Licenses__r
                ),
                (
                    SELECT
                        Id,
                        PJN_Parent_Account__c,
                        PJN_Parent_Account__r.PJN_Veeva_Network_Id__c
                    FROM
                        Affiliation__r
                )
            FROM
                Account
            WHERE
                Id = :accountId
        ];
    }

    private static void createAddress(Id accountId) {
        insert new PJN_Contact_Information__c (
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Account__c = accountId,
            PJN_Address_Line_1__c = 'whatever',
            PJN_City__c = 'New York',
            PJN_State__c = 'NY',
            PJN_Country__c = 'United States',
            PJN_Veeva_Network_Id__c = '933580259012006000'
        );
    }

    private static  void createLicense(Id accountId) {
        insert new PJN_License__c (
            RecordTypeId = SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get('PJN_DEA_License').getRecordTypeId(),
            PJN_Account__c = accountId,
            Name = 'whatever',
            PJN_Veeva_Network_Id__c = '932910724244966000'
        );
    }
}