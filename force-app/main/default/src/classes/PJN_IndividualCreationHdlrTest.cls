/**
 * @author      Mavens
 * @group       Account
 * @description Unit tests for PJN_IndividualCreationHdlr
 */
@isTest(isParallel=true) public with sharing class PJN_IndividualCreationHdlrTest {
    private static Id patientRecTypeId = SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get('PJN_Patient')
        .getRecordTypeId();

    @isTest private static void ensureNewPersonAccountCreatesAndSetsIndividual() {
        Account personAccount = new Account(
            FirstName = 'TEST-FIRST',
            LastName = 'TEST-LAST',
            RecordTypeId = patientRecTypeId
        );

        Test.startTest();
            insert personAccount;
        Test.stopTest();

        Account newPersonAccount = [
            SELECT
                Id,
                FirstName,
                LastName,
                PersonIndividualId,
                PersonIndividual.FirstName,
                PersonIndividual.LastName
            FROM
                Account
            WHERE
                Id = :personAccount.Id
            LIMIT
                1
        ];

        System.assertNotEquals(null, newPersonAccount.PersonIndividualId);
        System.assertEquals(newPersonAccount.FirstName, newPersonAccount.PersonIndividual.FirstName);
        System.assertEquals(newPersonAccount.LastName, newPersonAccount.PersonIndividual.LastName);
    }
    @isTest private static void ensureNewPersonAccountsCreateAndSetIndividual() {
        List<Account> personAccounts = new List<Account>();
        for (Integer index = 0; index < 200; index++) {
            personAccounts.add(
                new Account(
                    FirstName = 'TEST-FIRST' + index,
                    LastName = 'TEST-LAST' + index,
                    RecordTypeId = patientRecTypeId
                )
            );
        }

        Test.startTest();
            insert personAccounts;
        Test.stopTest();

        List<Account> newPersonAccounts = [
            SELECT
                Id,
                FirstName,
                LastName,
                PersonIndividualId,
                PersonIndividual.FirstName,
                PersonIndividual.LastName
            FROM
                Account
        ];

        System.assertEquals(200, newPersonAccounts.size());
        for (Account thisAccount : newPersonAccounts) {
            System.assertNotEquals(null, thisAccount.PersonIndividualId);
            System.assertEquals(thisAccount.FirstName, thisAccount.PersonIndividual.FirstName);
            System.assertEquals(thisAccount.LastName, thisAccount.PersonIndividual.LastName);
        }
    }

    @isTest private static void ensureOnlyNewPersonAccountsCreateAndSetIndividual() {
        Id householdRecTypeId = SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('IndustriesHousehold')
            .getRecordTypeId();
        List<Account> accounts = new List<Account>();
        for (Integer index = 0; index < 100; index++) {
            accounts.add(
                new Account(
                    FirstName = 'TEST-FIRST' + index,
                    LastName = 'TEST-LAST' + index,
                    RecordTypeId = patientRecTypeId
                )
            );
        }
        for (Integer index = 0; index < 100; index++) {
            accounts.add(
                new Account(
                    Name = 'TEST-FIRST' + index,
                    RecordTypeId = householdRecTypeId
                )
            );
        }

        Test.startTest();
            insert accounts;
        Test.stopTest();

        List<Account> newPersonAccounts = [
            SELECT
                Id,
                FirstName,
                LastName,
                PersonIndividualId,
                PersonIndividual.FirstName,
                PersonIndividual.LastName
            FROM
                Account
            WHERE
                PersonIndividualId != null
        ];

        System.assertEquals(100, newPersonAccounts.size());
        for (Account thisAccount : newPersonAccounts) {
            System.assertNotEquals(null, thisAccount.PersonIndividualId);
            System.assertEquals(thisAccount.FirstName, thisAccount.PersonIndividual.FirstName);
            System.assertEquals(thisAccount.LastName, thisAccount.PersonIndividual.LastName);
        }
    }
}