/**
 * @author      Mavens
 * @group       PrimaryCIChangeHdlrMVN
 * @description When any primary contact info changes map data to account fields
 */
public with sharing class PrimaryCIChangeHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {

    private Map<Id, PJN_Contact_Information__c> contactInformation;
    private List<Account> changedAccounts;

    public void handle() {
        getChangedAccounts();

        for (Account changedAccount : changedAccounts) {
            setPrimaryEmail(changedAccount);
            setPrimaryPhone(changedAccount);
            setPrimaryFax(changedAccount);
            setPrimaryAddress(changedAccount);
        }
    }

    private void getChangedAccounts() {
        Set<Id> contactInfoIds = new Set<Id>();
        changedAccounts = new List<Account>();
        for (Account acct : (List<Account>) Trigger.new) {
            if (hasChanged(acct)) {
                changedAccounts.add(acct);
                contactInfoIds.add(acct.PJN_Primary_Phone__c);
                contactInfoIds.add(acct.PJN_Primary_Email__c);
                contactInfoIds.add(acct.PJN_Primary_Address__c);
                contactInfoIds.add(acct.PJN_Primary_Fax__c);
            }
        }

        contactInformation = new Map<Id, PJN_Contact_Information__c>([
            SELECT
                Id,
                PJN_Phone__c,
                PJN_Email__c,
                PJN_Fax__c,
                PJN_Address_Line_1__c,
                PJN_Address_Line_2__c,
                PJN_City__c,
                PJN_State__c,
                PJN_Postal_Code__c,
                PJN_Country__c
            FROM
                PJN_Contact_Information__c
            WHERE
                Id IN :contactInfoIds
        ]);
    }

    private Boolean hasChanged(Account acct) {
        if (Trigger.isInsert) {
            return true;
        }
        Account oldAccount = (Account)Trigger.oldMap.get(acct.Id);
        return acct.PJN_Primary_Phone__c != oldAccount.PJN_Primary_Phone__c
            || acct.PJN_Primary_Email__c != oldAccount.PJN_Primary_Email__c
            || acct.PJN_Primary_Address__c != oldAccount.PJN_Primary_Address__c
            || acct.PJN_Primary_Fax__c != oldAccount.PJN_Primary_Fax__c;
    }

    private void setPrimaryEmail(Account changedAccount) {
        PJN_Contact_Information__c email = contactInformation.get(changedAccount.PJN_Primary_Email__c);
        changedAccount.PersonEmail = null;
        if (changedAccount.isPersonAccount && email != null) {
            changedAccount.PersonEmail = email.PJN_Email__c;
        }
    }

    private void setPrimaryPhone(Account changedAccount) {
        PJN_Contact_Information__c phone = contactInformation.get(changedAccount.PJN_Primary_Phone__c);
        changedAccount.Phone = null;
        if (phone != null) {
            changedAccount.Phone = phone.PJN_Phone__c;
        }
    }

    private void setPrimaryFax(Account changedAccount) {
        PJN_Contact_Information__c fax = contactInformation.get(changedAccount.PJN_Primary_Fax__c);
        changedAccount.Fax = null;
        if (fax != null) {
            changedAccount.Fax = fax.PJN_Fax__c;
        }
    }
    private void setPrimaryAddress(Account changedAccount) {
        PJN_Contact_Information__c address = contactInformation.get(changedAccount.PJN_Primary_Address__c);

        changedAccount.PersonMailingStreet = null;
        changedAccount.PersonMailingCity = null;
        changedAccount.PersonMailingState = null;
        changedAccount.PersonMailingPostalCode = null;
        changedAccount.PersonMailingCountry = null;

        changedAccount.BillingStreet = null;
        changedAccount.BillingCity = null;
        changedAccount.BillingState = null;
        changedAccount.BillingPostalCode = null;
        changedAccount.BillingCountry = null;

        if (address != null) {
            if (changedAccount.isPersonAccount) {
                changedAccount.PersonMailingStreet = address.PJN_Address_Line_1__c;
                if (String.isNotBlank(address.PJN_Address_Line_2__c)) {
                    changedAccount.PersonMailingStreet += '\n' + address.PJN_Address_Line_2__c;
                }
                changedAccount.PersonMailingCity = address.PJN_City__c;
                changedAccount.PersonMailingState = address.PJN_State__c;
                changedAccount.PersonMailingPostalCode = address.PJN_Postal_Code__c;
                changedAccount.PersonMailingCountry = address.PJN_Country__c;
            } else {
                changedAccount.BillingStreet = address.PJN_Address_Line_1__c;
                if (String.isNotBlank(address.PJN_Address_Line_2__c)) {
                    changedAccount.BillingStreet += '\n' + address.PJN_Address_Line_2__c;
                }
                changedAccount.BillingCity = address.PJN_City__c;
                changedAccount.BillingState = address.PJN_State__c;
                changedAccount.BillingPostalCode = address.PJN_Postal_Code__c;
                changedAccount.BillingCountry = address.PJN_Country__c;
            }
        }
    }
}