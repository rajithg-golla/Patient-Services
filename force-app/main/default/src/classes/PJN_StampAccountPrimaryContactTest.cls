/**
 * @author      Mavens
 * @group       Account
 * @description Unit tests for PJN_StampAccountPrimaryContact
 */
@isTest(isParallel=true) private class PJN_StampAccountPrimaryContactTest {

    @isTest private static void ensureNewAccountsSetPrimaryContactToPersonContactId() {
        List<Account> accounts = new List<Account>();

        Id PatientRecTypeId = SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Patient')
            .getRecordTypeId();

        for (Integer i=0; i<200; i++) {
            accounts.add(
                new Account(
                    LastName = 'lastname' + i,
                    RecordTypeId = PatientRecTypeId
                )
            );
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> newAccounts = [
            SELECT
                Id,
                PersonContactId,
                HealthCloudGA__PrimaryContact__c
            FROM
                Account
            WHERE
                HealthCloudGA__PrimaryContact__c != null
        ];

        System.assertEquals(200, newAccounts.size());
        for (Account acct : newAccounts) {
            System.assertEquals(acct.PersonContactId, acct.HealthCloudGA__PrimaryContact__c);
        }
    }

}