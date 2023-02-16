/**
 * @author      Mavens
 * @group       Account
 * @description A bug in healthcloud does not set the primary contact for a patient to the
 *              personcontactid when the account is created so this trigger handles that.
 */
public with sharing class PJN_StampAccountPrimaryContact implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        List<Account> accounts = [
            SELECT
                Id,
                PersonContactId,
                HealthCloudGA__PrimaryContact__c
            FROM
                Account
            WHERE
                Id IN :Trigger.new
        ];

        for (Account acct: accounts) {
            acct.HealthCloudGA__PrimaryContact__c = acct.PersonContactId;
        }

        update accounts;
    }
}