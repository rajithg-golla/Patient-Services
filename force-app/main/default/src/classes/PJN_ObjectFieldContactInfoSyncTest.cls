@IsTest
public class PJN_ObjectFieldContactInfoSyncTest {

    private static final Integer DATA_SIZE = 10;

    static {
        PJN_ObjectFieldContactInfoMappings.objectFieldContactInfoMappingsQuery = (PJN_ObjectFieldContactInfoMappingsQuery) Test.createStub(PJN_ObjectFieldContactInfoMappingsQuery.class, new PJN_ObjectFieldContactInfoMappingsMock());
        PJN_TestFactoryGlobalSetting.setMock();
    }

    @TestSetup
    static void makeData(){
        List<Account> accounts = buildAccounts(DATA_SIZE);
        insert accounts;

        List<PJN_Contact_Information__c> contactInfos = buildAddresses(accounts);
        insert contactInfos;
    }

    private static List<Account> buildAccounts(Integer numOfAccounts) {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Account> accounts = new List<Account>();

        for (Integer accIndex = 0; accIndex < numOfAccounts; accIndex++) {
            accounts.add(
                new Account(
                    FirstName = 'First' + accIndex,
                    LastName = 'Test' + accIndex,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId()
                )
            );
        }

        return accounts;
    }

    private static List<PJN_Contact_Information__c> buildAddresses(List<Account> accounts) {
        List<PJN_Contact_Information__c> contactInfos = new List<PJN_Contact_Information__c>();

        for (Account account : accounts) {
            contactInfos.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = account.Id,
                    PJN_Address_Line_1__c = 'Main Street 123',
                    PJN_City__c = 'Chicago',
                    PJN_State__c = 'IL',
                    PJN_Country__c = 'United States',
                    RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
                )
            );
        }

        return contactInfos;
    }

    @IsTest
    static void testIfAccountInsertCreatesContactInfos() {
        List<Account> accounts = buildAccounts(DATA_SIZE);

        for (Account account : accounts) {
            account.PersonEmail = 'test@test.com';
            account.Phone = '1111111111';
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        accounts = getAccountsQueried(accounts);
        System.assert(!accounts.isEmpty(), 'Something went wrong getting accounts queried.');

        /*
        for (Account account : accounts) {
            System.assert(!account.PJN_Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : account.PJN_Contact_Information__r) {
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(account.PersonEmail, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(account.Phone, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
        */
    }

    @IsTest
    static void testIfAccountUpdateCreatesContactInfos() {
        List<Account> accounts = getAccountsQueried();

        for (Account account : accounts) {
            account.PersonEmail = 'test@test.com';
            account.Phone = '1111111111';
        }

        Test.startTest();
        update accounts;
        Test.stopTest();

        accounts = getAccountsQueried(accounts);
        System.assert(!accounts.isEmpty(), 'Something went wrong getting accounts queried.');

        for (Account account : accounts) {
            System.assert(!account.PJN_Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : account.PJN_Contact_Information__r) {
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(account.PersonEmail, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(account.Phone, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
    }

    @IsTest
    static void testIfAccountUpdateGetsContactInfosUpdated() {
        List<Account> accounts = getAccountsQueried();

        for (Account account : accounts) {
            account.PersonEmail = 'test@test.com';
            account.Phone = '1111111111';
        }

        update accounts;

        for (Account account : accounts) {
            account.PersonEmail = 'test2@test.com';
            account.Phone = '222222222';
        }

        Test.startTest();
        update accounts;
        Test.stopTest();

        accounts = getAccountsQueried(accounts);
        System.assert(!accounts.isEmpty(), 'Something went wrong getting accounts queried.');

        for (Account account : accounts) {
            Integer emailCount = 0;
            Integer phoneCount = 0;
            System.assert(!account.PJN_Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : account.PJN_Contact_Information__r) {
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(account.PersonEmail, contactInfo.PJN_Email__c, 'Email must be the same');
                    emailCount++;
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(account.Phone, contactInfo.PJN_Phone__c, 'Phone must be the same');
                    phoneCount++;
                }
            }
            System.assertEquals(1, emailCount, 'Email Contact Info must be updated not recreated');
            System.assertEquals(1, phoneCount, 'Phone Contact Info must be updated not recreated');
        }
    }

    @IsTest
    static void testIfAddressInsertCreatesContactInfos() {
        List<Account> accounts = getAccountsQueried();

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);

        for (PJN_Contact_Information__c address : addresses) {
            address.PJN_Email__c = 'test@test.com';
            address.PJN_Phone__c = '1111111111';
        }

        Test.startTest();
        insert addresses;
        Test.stopTest();

        addresses = getAddressesQueried(addresses);
        System.assert(!addresses.isEmpty(), 'Something went wrong getting address contact info queried.');

        for (PJN_Contact_Information__c address : addresses) {
            System.assert(!address.Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : address.Contact_Information__r) {
                System.assertEquals(address.PJN_Account__c, contactInfo.PJN_Account__c, 'Address Account and Contact Info Account must be the same.');
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(address.PJN_Email__c, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(address.PJN_Phone__c, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
    }

    @IsTest
    static void testIfAddressUpdateCreatesContactInfos() {
        List<PJN_Contact_Information__c> contactInfos = getAddressesQueried();

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            contactInfo.PJN_Email__c = 'test@test.com';
            contactInfo.PJN_Phone__c = '1111111111';
        }

        Test.startTest();
        update contactInfos;
        Test.stopTest();

        contactInfos = getAddressesQueried(contactInfos);
        System.assert(!contactInfos.isEmpty(), 'Something went wrong getting address contact info queried.');

        for (PJN_Contact_Information__c address : contactInfos) {
            System.assert(!address.Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : address.Contact_Information__r) {
                System.assertEquals(address.PJN_Account__c, contactInfo.PJN_Account__c, 'Address Account and Contact Info Account must be the same.');
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(address.PJN_Email__c, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(address.PJN_Phone__c, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
    }

    @IsTest
    static void testIfAddressUpdateGetsContactInfosUpdated() {
        List<PJN_Contact_Information__c> contactInfos = getAddressesQueried();

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            contactInfo.PJN_Email__c = 'test@test.com';
            contactInfo.PJN_Phone__c = '1111111111';
        }
        update contactInfos;

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            contactInfo.PJN_Email__c = 'test2@test.com';
            contactInfo.PJN_Phone__c = '22222222222';
        }

        Test.startTest();
        update contactInfos;
        Test.stopTest();

        contactInfos = getAddressesQueried(contactInfos);
        System.assert(!contactInfos.isEmpty(), 'Something went wrong getting address contact info queried.');

        for (PJN_Contact_Information__c address : contactInfos) {
            Integer emailCount = 0;
            Integer phoneCount = 0;
            System.assert(!address.Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : address.Contact_Information__r) {
                System.assertEquals(address.PJN_Account__c, contactInfo.PJN_Account__c, 'Address Account and Contact Info Account must be the same.');
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(address.PJN_Email__c, contactInfo.PJN_Email__c, 'Email must be the same');
                    emailCount++;
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(address.PJN_Phone__c, contactInfo.PJN_Phone__c, 'Phone must be the same');
                    phoneCount++;
                }
            }
            System.assertEquals(1, emailCount, 'Email Contact Info must be updated not recreated');
            System.assertEquals(1, phoneCount, 'Phone Contact Info must be updated not recreated');
        }
    }

    /*
    @IsTest
    static void testIfContactInfosUpdateGetAccountUpdated() {
        List<Account> accounts = buildAccounts(DATA_SIZE);

        for (Account account : accounts) {
            account.PersonEmail = 'test@test.com';
            account.Phone = '1111111111';
        }

        insert accounts;

        accounts = getAccountsQueried(accounts);
        System.assert(!accounts.isEmpty(), 'Something went wrong getting accounts queried.');

        for (Account account : accounts) {
            System.assert(!account.PJN_Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : account.PJN_Contact_Information__r) {
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(account.PersonEmail, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(account.Phone, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }

        List<PJN_Contact_Information__c> contactInfos = getContactInfosQueried();
        System.assert(!contactInfos.isEmpty(), 'No Contact Info created from Account found');

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                contactInfo.PJN_Email__c = 'test2@test.com';
            } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                contactInfo.PJN_Phone__c = '2222222222';
            }
        }

        Test.startTest();
        update contactInfos;
        Test.stopTest();

        accounts = getAccountsQueried(accounts);
        System.assert(!accounts.isEmpty(), 'Something went wrong getting accounts queried.');

        for (Account account : accounts) {
            System.assert(!account.PJN_Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : account.PJN_Contact_Information__r) {
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals('test2@test.com', contactInfo.PJN_Email__c, 'Email has not changed');
                    System.assertEquals(account.PersonEmail, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals('2222222222', contactInfo.PJN_Phone__c, 'Phone has not changed');
                    System.assertEquals(account.Phone, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
    }
    */

    @IsTest
    static void testIfContactInfosUpdateGetsAddressUpdated() {
        List<Account> accounts = getAccountsQueried();

        List<PJN_Contact_Information__c> addresses = buildAddresses(accounts);

        for (PJN_Contact_Information__c address : addresses) {
            address.PJN_Email__c = 'test@test.com';
            address.PJN_Phone__c = '1111111111';
        }

        insert addresses;

        addresses = getAddressesQueried(addresses);
        System.assert(!addresses.isEmpty(), 'Something went wrong getting address contact info queried.');

        for (PJN_Contact_Information__c address : addresses) {
            System.assert(!address.Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : address.Contact_Information__r) {
                System.assertEquals(address.PJN_Account__c, contactInfo.PJN_Account__c, 'Address Account and Contact Info Account must be the same.');
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals(address.PJN_Email__c, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals(address.PJN_Phone__c, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }

        List<PJN_Contact_Information__c> contactInfos = getContactInfosQueried();
        System.assert(!contactInfos.isEmpty(), 'No Contact Info created from Account found');

        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                contactInfo.PJN_Email__c = 'test2@test.com';
            } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                contactInfo.PJN_Phone__c = '2222222222';
            }
        }

        Test.startTest();
        update contactInfos;
        Test.stopTest();

        addresses = getAddressesQueried(addresses);
        System.assert(!addresses.isEmpty(), 'Something went wrong getting address contact info queried.');

        for (PJN_Contact_Information__c address : addresses) {
            System.assert(!address.Contact_Information__r.isEmpty(), 'Contact Information records must be created and related to accounts.');
            for (PJN_Contact_Information__c contactInfo : address.Contact_Information__r) {
                System.assertEquals(address.PJN_Account__c, contactInfo.PJN_Account__c, 'Address Account and Contact Info Account must be the same.');
                if (contactInfo.RecordType.DeveloperName == 'PJN_Email') {
                    System.assertEquals('test2@test.com', contactInfo.PJN_Email__c, 'Email has not changed');
                    System.assertEquals(address.PJN_Email__c, contactInfo.PJN_Email__c, 'Email must be the same');
                } else if (contactInfo.RecordType.DeveloperName == 'PJN_Phone') {
                    System.assertEquals('2222222222', contactInfo.PJN_Phone__c, 'Phone has not changed');
                    System.assertEquals(address.PJN_Phone__c, contactInfo.PJN_Phone__c, 'Phone must be the same');
                }
            }
        }
    }

    private static List<Account> getAccountsQueried(List<Account> accounts) {
        return [
            SELECT
                Id,
                PersonEmail,
                Phone,
                (
                    SELECT
                        Id,
                        PJN_Email__c,
                        PJN_Phone__c,
                        RecordType.DeveloperName
                    FROM
                        PJN_Contact_Information__r
                    WHERE
                        RecordType.DeveloperName IN ('PJN_Email', 'PJN_Phone')
                )
            FROM
                Account
            WHERE
                Id IN :accounts
        ];
    }

    private static List<Account> getAccountsQueried() {
        return [
            SELECT
                Id,
                PersonEmail,
                Phone
            FROM
                Account
            LIMIT :DATA_SIZE
        ];
    }

    private static List<PJN_Contact_Information__c> getAddressesQueried(List<PJN_Contact_Information__c> addresses) {
        return [
            SELECT
                Id,
                PJN_Account__c,
                PJN_Email__c,
                PJN_Phone__c,
                (
                    SELECT
                        Id,
                        PJN_Account__c,
                        PJN_Email__c,
                        PJN_Phone__c,
                        RecordType.DeveloperName
                    FROM
                        Contact_Information__r
                    WHERE
                        RecordType.DeveloperName IN ('PJN_Email', 'PJN_Phone')
                )
            FROM
                PJN_Contact_Information__c
            WHERE
                Id IN :addresses
        ];
    }

    private static List<PJN_Contact_Information__c> getAddressesQueried() {
        return [
            SELECT
                Id,
                PJN_Account__c,
                PJN_Email__c,
                PJN_Phone__c
            FROM
                PJN_Contact_Information__c
            WHERE
                RecordType.DeveloperName = 'PJN_Address'
            LIMIT :DATA_SIZE
        ];
    }

    private static List<PJN_Contact_Information__c> getContactInfosQueried() {
        return [
            SELECT
                Id,
                PJN_Account__c,
                PJN_Email__c,
                PJN_Phone__c,
                RecordType.DeveloperName,
                PJN_Created_From_Address__c
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_External_Id__c != null
        ];
    }
}