/**
 * @author Mavens
 * @date Mar 2019
 * @description Set Contact Information record as primary and update the corresponding primary field
 *              on the Account
 * @group ContactInformation
 */
public with sharing class PJN_SetPrimaryContactInfo implements PJN_TriggerDispatcher.HandlerInterface {

    public static List<PJN_Contact_Information__c> cisToSetAsPrimary = new List<PJN_Contact_Information__c>();

    Map<String, RecordTypeInfo> ciRecordTypes;
    Map<Id, Map<String, Id>> accountToPrimaryFields;

    /**
     * Initialize variables
     */
    public PJN_SetPrimaryContactInfo() {
        ciRecordTypes = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();
        accountToPrimaryFields = new Map<Id, Map<String, Id>>();
    }

    /**
     * Handle trigger
     */
    public void handle() {
        if (Trigger.isBefore) {
            for (PJN_Contact_Information__c contactInfo : (List<PJN_Contact_Information__c>) Trigger.new) {
                if (contactInfo.PJN_Set_as_Primary__c) {
                    cisToSetAsPrimary.add(contactInfo);
                    contactInfo.PJN_Set_as_Primary__c = false;
                }
            }
        } else {
            for (PJN_Contact_Information__c contactInfo : cisToSetAsPrimary) {
                if (!accountToPrimaryFields.containsKey(contactInfo.PJN_Account__c)) {
                    accountToPrimaryFields.put(contactInfo.PJN_Account__c, new Map<String, Id>());
                }
                String acctFieldToUpdate = getFieldToUpdate(contactInfo);
                if (String.isNotBlank(acctFieldToUpdate)) {
                    accountToPrimaryFields.get(contactInfo.PJN_Account__c).put(acctFieldToUpdate, contactInfo.Id);
                }
            }
            queryAndUpdateAccounts(accountToPrimaryFields);
        }
    }

    /**
     * Get the field to update on the Account record based on the contact information record type
     * @param  contactInfo contact information record
     * @returns String
     */
    private String getFieldToUpdate(PJN_Contact_Information__c contactInfo) {
        String fieldToUpdate = null;
        PJN_Global_Setting__mdt globalSetting = PJN_Utilities.globalSetting;

        Set<Id> addressRecTypeIds = new Set<Id>();
        for (String recTypeName : globalSetting.PJN_Contact_Info_Address_Record_Types__c.split(';')) {
            addressRecTypeIds.add(ciRecordTypes.get(recTypeName).getRecordTypeId());
        }
        if (addressRecTypeIds.contains(contactInfo.RecordTypeId)) {
            fieldToUpdate = 'PJN_Primary_Address__c';
        }

        Set<Id> emailRecTypeIds = new Set<Id> ();
        for (String recTypeName : globalSetting.PJN_Contact_Info_Email_Record_Types__c.split(';')) {
            emailRecTypeIds.add(ciRecordTypes.get(recTypeName).getRecordTypeId());
        }
        if (emailRecTypeIds.contains(contactInfo.RecordTypeId)) {
            fieldToUpdate = 'PJN_Primary_Email__c';
        }


        Set<Id> phoneRecTypeIds = new Set<Id> ();
        for (String recTypeName : globalSetting.PJN_Contact_Info_Phone_Record_Types__c.split(';')) {
            phoneRecTypeIds.add(ciRecordTypes.get(recTypeName).getRecordTypeId());
        }
        if (phoneRecTypeIds.contains(contactInfo.RecordTypeId)) {
            fieldToUpdate = 'PJN_Primary_Phone__c';
        }

        Set<Id> faxRecTypeIds = new Set<Id> ();
        for (String recTypeName : globalSetting.PJN_Contact_Info_Fax_Record_Types__c.split(';')) {
            faxRecTypeIds.add(ciRecordTypes.get(recTypeName).getRecordTypeId());
        }
        if (faxRecTypeIds.contains(contactInfo.RecordTypeId)) {
            fieldToUpdate = 'PJN_Primary_Fax__c';
        }
        return fieldToUpdate;
    }

    /**
     * query accounts and update them with the primary field value
     * @param  accountToPrimaryFields map of fields to be updated by account id
     */
    private void queryAndUpdateAccounts(Map<Id, Map<String, Id>> accountToPrimaryFields) {
        List<Account> accounts = getAccounts(accountToPrimaryFields.keySet());
        for (Account acct : accounts) {
            Map<String, Id> primaryFieldsToUpdate = accountToPrimaryFields.get(acct.Id);
            for (String field : primaryFieldsToUpdate.keySet()) {
                acct.put(field, primaryFieldsToUpdate.get(field));
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
                PJN_Primary_Address__c,
                PJN_Primary_Email__c,
                PJN_Primary_Phone__c,
                PJN_Primary_Fax__c
            FROM
                Account
            WHERE
                Id IN :accountIds
        ];
    }
}