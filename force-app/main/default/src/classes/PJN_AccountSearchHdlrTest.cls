/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Unit tests for PJN_AccountSearchHdlr
 */
@isTest(isParallel=true) private class PJN_AccountSearchHdlrTest {

    /**
     * Bulk number to create data
     */
    private static final Integer BULK_NUMBER = 50;

    /**
     * Patient record type Id for Account object
     */
    private static final Id PATIENT_RECORDTYPE_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();

    /**
     * Physician record type Id for Account object
     */
    private static final Id PHYSICIAN_RECORDTYPE_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId();

    /**
     * Organization record type Id for Account Object
     */
    private static final Id ORGANIZATION_RECORDTYPE_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId();

    /**
     * Phone record type id for Contact Information object
     */
    private static final ID PHONE_RECORDTYPE_ID = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId();

    /**
     * Phone record type id for Contact Information object
     */
    private static final ID FAX_RECORDTYPE_ID = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Fax').getRecordTypeId();

    /**
     * Address record type id for Contact Information object
     */
    private static final ID ADDRESS_RECORDTYPE_ID = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId();

    /**
     * Email record type id for Contact Information object
     */
    private static final ID EMAIL_RECORDTYPE_ID = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId();

    @TestSetup
    static void makeData(){
        List<Account> accounts = buildPatients(BULK_NUMBER);
        accounts.addAll(buildPhysicians(BULK_NUMBER));
        accounts.addAll(buildOrganizations(BULK_NUMBER));
        insert accounts;

        Test.startTest();
        List<PJN_Contact_Information__c> cis = buildPhoneContactInformation(accounts);
        cis.addAll(buildFaxContactInformation(accounts));
        cis.addAll(buildAddressContactInformation(accounts));
        cis.addAll(buildEmailContactInformation(accounts));
        insert cis;
        Test.stopTest();
    }

    private static List<Account> buildPatients(Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer acctIndex = 0; acctIndex < numberOfAccounts; acctIndex++) {
            accounts.add (
                    new Account(
                    LastName = 'Test ' + numberOfAccounts,
                    FirstName = 'Test ' + numberOfAccounts,
                    RecordTypeId = PATIENT_RECORDTYPE_ID,
                    MVN_Birthdate__c = Date.newInstance(2015,1,1)
                )
            );
        }

        return accounts;
    }

    private static List<Account> buildPhysicians(Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer acctIndex = 0; acctIndex < numberOfAccounts; acctIndex++) {
            accounts.add (
                    new Account(
                    LastName = 'Test ' + numberOfAccounts,
                    FirstName = 'Test ' + numberOfAccounts,
                    RecordTypeId = PHYSICIAN_RECORDTYPE_ID
                )
            );
        }

        return accounts;
    }

    private static List<Account> buildOrganizations(Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer acctIndex = 0; acctIndex < numberOfAccounts; acctIndex++) {
            accounts.add (
                    new Account(
                    Name = 'Test ' + numberOfAccounts,
                    RecordTypeId = ORGANIZATION_RECORDTYPE_ID
                )
            );
        }

        return accounts;
    }

    private static List<PJN_Contact_Information__c> buildPhoneContactInformation(List<Account> accounts) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();

        for (Account account : accounts) {
            cis.add (
                    new PJN_Contact_Information__c(
                        PJN_Account__c = account.Id,
                        PJN_Phone__c = '5556667777',
                        RecordTypeId = PHONE_RECORDTYPE_ID
                )
            );
        }

        return cis;
    }

    private static List<PJN_Contact_Information__c> buildFaxContactInformation(List<Account> accounts) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();

        for (Account account : accounts) {
            cis.add (
                    new PJN_Contact_Information__c(
                        PJN_Account__c = account.Id,
                        PJN_Phone__c = '5556668888',
                        RecordTypeId = FAX_RECORDTYPE_ID
                )
            );
        }

        return cis;
    }

    private static List<PJN_Contact_Information__c> buildAddressContactInformation(List<Account> accounts) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();

        for (Account account : accounts) {
            cis.add (
                    new PJN_Contact_Information__c(
                        PJN_Account__c = account.Id,
                        PJN_Address_Line_1__c = 'Main Street 123',
                        PJN_City__c = 'Chicago',
                        PJN_Country__c = 'United States',
                        PJN_Postal_Code__c = '11111',
                        RecordTypeId = ADDRESS_RECORDTYPE_ID
                )
            );
        }

        return cis;
    }

    private static List<PJN_Contact_Information__c> buildEmailContactInformation(List<Account> accounts) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();

        for (Account account : accounts) {
            cis.add (
                    new PJN_Contact_Information__c(
                        PJN_Account__c = account.Id,
                        PJN_Email__c = 'test@invalid.test',
                        RecordTypeId = Email_RECORDTYPE_ID
                )
            );
        }

        return cis;
    }

    private static void initializeFieldSettingsByType(String accountFieldName, String ciRecordTypeName, String ciFieldName) {
        PJN_AccountSearchLightningUtil.fieldSettingsByType = new Map<String, List<PJN_FieldWrapper>> {
            'Person_Search_Query' => new List<PJN_FieldWrapper> {
                new PJN_FieldWrapper(
                    new PJN_Field_Setting__mdt (
                        PJN_Object__c = 'Account',
                        PJN_Field__c = accountFieldName
                    )
                ),
                new PJN_FieldWrapper(
                    new PJN_Field_Setting__mdt (
                        PJN_Object__c = 'PJN_Contact_Information__c',
                        PJN_Field__c = ciFieldName,
                        PJN_Contact_Info_Record_Type__c = ciRecordTypeName
                    )
                )
            }
        };
    }

    @isTest
    private static void noSearchTermsReturnsNoResults() {
        //exercise the getFinalResults method when no ids found
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account();
        req.contactInfo = new PJN_Contact_Information__c();
        req.isPersonSearch = true;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        List<PJN_AccountSearchRslt> results = searchHdlr.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @isTest
    private static void itShouldBuildProperSearchForAccountWithName() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account(LastName = 'Dean', FirstName = 'James');
        req.contactInfo = new PJN_Contact_Information__c();
        req.isPersonSearch = true;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        searchHdlr.search(req);
        Test.stopTest();

        List<String> expectedSearchStrings = new List<String> {
            'FIND \'Dean AND James\' IN ALL FIELDS RETURNING Account (Id WHERE isPersonAccount = :isPersonSearch)'
        };

        System.assertEquals(expectedSearchStrings, PJN_AccountSearchHdlr.searchStrings);
    }

    @isTest
    private static void itShouldBuildProperSearchForAccountWithNameAndBirthdate() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        // perform a patient search
        req.account = new Account(
            RecordTypeId = PATIENT_RECORDTYPE_ID,
            LastName = 'Dean',
            FirstName = 'James',
            MVN_Birthdate__c = Date.newInstance(2015,1,1)
        );
        req.contactInfo = new PJN_Contact_Information__c();
        req.isPersonSearch = true;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        searchHdlr.search(req);
        Test.stopTest();

        List<String> expectedSearchStrings = new List<String> {
            'FIND \'Dean AND James\' IN ALL FIELDS RETURNING Account (Id WHERE MVN_Birthdate__c=2015-01-01 AND isPersonAccount = :isPersonSearch AND (RecordType.DeveloperName = \'PJN_Patient\'))'
        };

        System.assertEquals(expectedSearchStrings, PJN_AccountSearchHdlr.searchStrings);
    }

    @isTest
    private static void itShouldBuildProperSearchForAccountWithOnlyBirthdate() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        // perform a patient search
        req.account = new Account(
            RecordTypeId = PATIENT_RECORDTYPE_ID,
            MVN_Birthdate__c = Date.newInstance(2015,1,1)
        );
        req.contactInfo = new PJN_Contact_Information__c();
        req.isPersonSearch = true;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        List<PJN_AccountSearchRslt> results = searchHdlr.search(req);
        Test.stopTest();

        System.assertEquals(BULK_NUMBER, results.size());
        List<String> expectedSearchStrings = new List<String> {
            'SELECT Id FROM Account WHERE MVN_Birthdate__c=2015-01-01 AND isPersonAccount = :isPersonSearch AND (RecordType.DeveloperName = \'PJN_Patient\')'
        };

        System.assertEquals(expectedSearchStrings, PJN_AccountSearchHdlr.searchStrings);
    }

    @isTest
    private static void itShouldBuildProperSearchForEmail() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account();
        req.contactInfo = new PJN_Contact_Information__c(PJN_Email__c = 'james.dean@test.com');
        req.isPersonSearch = true;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        searchHdlr.search(req);
        Test.stopTest();

        String expectedSearchString = 'FIND \'james.dean@test.com\' IN EMAIL FIELDS RETURNING PJN_Contact_Information__c (PJN_Account__c WHERE (RecordType.DeveloperName =';

        String searchString = PJN_AccountSearchHdlr.searchStrings[0];
        System.assert(searchString.startsWith(expectedSearchString));
    }

    @isTest
    private static void itShouldBuildProperSearchForPhoneAndFax() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account(
            RecordTypeId = PHYSICIAN_RECORDTYPE_ID
        );
        req.contactInfo = new PJN_Contact_Information__c(
            PJN_Phone__c = '5556667777',
            PJN_Fax__c = '5556668888'
        );
        req.isPersonSearch = true;

        Account acct = [SELECT Id FROM Account LIMIT 1];
        Map<Id, PJN_Contact_Information__c> cis = new Map<Id, PJN_Contact_Information__c> ([
            SELECT Id
            FROM PJN_Contact_Information__c
            WHERE PJN_Account__r.RecordTypeId=:PHYSICIAN_RECORDTYPE_ID
            AND (RecordType.DeveloperName = 'PJN_Phone' OR RecordType.DeveloperName = 'PJN_Fax')
        ]);
        List<Id> fixedSearchResults = new List<Id>();
        //fixedSearchResults.add(acct.Id);
        fixedSearchResults.addAll(cis.keySet());

        Test.startTest();
        Test.setFixedSearchResults(fixedSearchResults);
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        searchHdlr.search(req);
        Test.stopTest();

        List<String> expectedSearchStrings = new List<String> {
            'FIND \'5556667777\' IN PHONE FIELDS RETURNING PJN_Contact_Information__c (PJN_Account__c WHERE (RecordType.DeveloperName = \'PJN_Phone\') AND PJN_Account__r.RecordType.DeveloperName IN :accountSearchRecTypes)',
            'FIND \'5556668888\' IN PHONE FIELDS RETURNING PJN_Contact_Information__c (PJN_Account__c WHERE PJN_Account__c IN :currentAccountIds AND (RecordType.DeveloperName = \'PJN_Fax\'))'
        };

        System.assertEquals(expectedSearchStrings[0], PJN_AccountSearchHdlr.searchStrings[0]);
        System.assertEquals(expectedSearchStrings[1], PJN_AccountSearchHdlr.searchStrings[1]);
    }

    @isTest
    private static void itShouldThrowErrorWhenSearchReturnsTooManyResuts() {
        PJN_AccountSearchHdlr.SEARCH_MAX = 1; // force the error

        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account();
        req.isPersonSearch = true;

        PJN_Contact_Information__c searchForEmail = [
            SELECT Id, PJN_Email__c
            FROM PJN_Contact_Information__c
            WHERE RecordType.DeveloperName = 'PJN_Email'
            LIMIT 1
        ];
        req.contactInfo = new PJN_Contact_Information__c(PJN_Email__c = searchForEmail.PJN_Email__c);

        Test.startTest();
        Test.setFixedSearchResults(new List<Id>{searchForEmail.Id});
        PJN_AccountSearchHdlr.PJNSearchException except;
        try {
            PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
            searchHdlr.search(req);
        } catch (PJN_AccountSearchHdlr.PJNSearchException ex) {
            except = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, except);
        System.assertEquals(
            String.format(Label.PJN_Account_Search_Too_Many_Results, new List<String>{'Email'}),
            except.getMessage()
        );
    }

    @isTest
    private static void itShouldReturnTheAccountIdWhenInsertIsCalled() {
        Account acct = [SELECT Id, HealthCloudGA__SourceSystemId__c, PJN_Veeva_Network_Id__c FROM Account LIMIT 1];
        PJN_AccountSearchRslt searchRslt = new PJN_AccountSearchRslt(acct, null, null);
        searchRslt.accountDetail = acct;

        Test.startTest();
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();
        Id returnedId = searchHdlr.insertAccountDetails(searchRslt);
        Test.stopTest();

        System.assertEquals(acct.Id, returnedId);
    }

    @isTest
    private static void itShouldReturnEmptyListForAccountWithDetailsCall() {
        PJN_AccountSearchHdlr searchHdlr = new PJN_AccountSearchHdlr();

        System.assertEquals(
            new List<PJN_AccountSearchRslt>(),
            searchHdlr.getAccountsWithDetails(new PJN_AccountSearchRqst())
        );
    }
}