/**
 * @author      Mavens
 * @group       ContactInformation
 * @description Set Contact Information record as shipping or sms and update the corresponding shipping/sms field
 *              on the Account
 */
public with sharing class MVN_SetShippingAndSMSContactInfoHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public static List<PJN_Contact_Information__c> cisToSetAsShipping = new List<PJN_Contact_Information__c>();
    public static List<PJN_Contact_Information__c> cisToSetAsSMS = new List<PJN_Contact_Information__c>();

    Map<String, RecordTypeInfo> ciRecordTypes;
    Map<Id, Map<String, Id>> accountToShippingOrSMSFields;

    /**
     * Initialize variables
     */
    public MVN_SetShippingAndSMSContactInfoHdlr() {
        ciRecordTypes = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();
        accountToShippingOrSMSFields = new Map<Id, Map<String, Id>>();
    }

    /**
     * Handle trigger
     */
    public void handle() {
        if (Trigger.isBefore) {
            for (PJN_Contact_Information__c contactInfo : (List<PJN_Contact_Information__c>) Trigger.new) {
                if (contactInfo.MVN_Set_as_Shipping__c) {
                    cisToSetAsShipping.add(contactInfo);
                    contactInfo.MVN_Set_as_Shipping__c = false;
                }
                if (contactInfo.MVN_Set_as_SMS__c) {
                    cisToSetAsSMS.add(contactInfo);
                    contactInfo.MVN_Set_as_SMS__c = false;
                }
            }
        } else {
            buildAccountToShippingOrSMSFields(cisToSetAsShipping, 'MVN_Shipping_Address__c');
            buildAccountToShippingOrSMSFields(cisToSetAsSMS, 'MVN_SMS_Phone__c');
            queryAndUpdateAccounts(accountToShippingOrSMSFields);
        }
    }

    private void buildAccountToShippingOrSMSFields(List<PJN_Contact_Information__c> cisToSetAsShippingOrSMS, String acctFieldToUpdate) {
        if (cisToSetAsShippingOrSMS.isEmpty() || String.isBlank(acctFieldToUpdate)) {
            return;
        }
        for (PJN_Contact_Information__c contactInfo : cisToSetAsShippingOrSMS) {
            if (!accountToShippingOrSMSFields.containsKey(contactInfo.PJN_Account__c)) {
                accountToShippingOrSMSFields.put(contactInfo.PJN_Account__c, new Map<String, Id>());
            }
            accountToShippingOrSMSFields.get(contactInfo.PJN_Account__c).put(acctFieldToUpdate, contactInfo.Id);
        }
    }

    /**
     * query accounts and update them with the primary field value
     * @param  accountToShippingOrSMSFields map of fields to be updated by account id
     */
    private void queryAndUpdateAccounts(Map<Id, Map<String, Id>> accountToShippingOrSMSFields) {
        List<Account> accounts = getAccounts(accountToShippingOrSMSFields.keySet());
        for (Account acct : accounts) {
            Map<String, Id> fieldsToUpdate = accountToShippingOrSMSFields.get(acct.Id);
            for (String field : fieldsToUpdate.keySet()) {
                acct.put(field, fieldsToUpdate.get(field));
            }
        }
        update accounts;
    }

    /**
     * get accounts
     * @param  accountIds account id set
     * @returns List<Account>
     */
    private List<Account> getAccounts(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                MVN_Shipping_Address__c,
                MVN_SMS_Phone__c
            FROM
                Account
            WHERE
                Id IN :accountIds
        ];
    }
}