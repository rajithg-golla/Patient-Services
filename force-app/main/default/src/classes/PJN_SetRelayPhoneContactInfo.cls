/*
 * Handles setting the Relay Phone lookup field on an Account when Set as Relay Phone is checked on
 * a Contact Information record.
 *
 * @author  Mavens
 * @date    Oct 2021
 * @group   Relay Network
 */
public with sharing class PJN_SetRelayPhoneContactInfo implements PJN_TriggerDispatcher.HandlerInterface {

    private static List<PJN_Contact_Information__c> cisToSetAsRelayPhone = new List<PJN_Contact_Information__c>();
    @TestVisible
    private static final String notPhoneRelayError = 'Cannot set as Relay Phone. Relay Phone must be a Phone record type.';
    
    public void handle() {
        if (Trigger.isBefore) {
            // Get Phone record type Ids from Global Settings
            PJN_Global_Setting__mdt globalSetting = PJN_Utilities.globalSetting;
            Set<Id> phoneRecTypeIds = new Set<Id> ();
            Map<String, RecordTypeInfo> ciRecordTypes = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();
            
            for (String recTypeName : globalSetting.PJN_Contact_Info_Phone_Record_Types__c.split(';')) {
                phoneRecTypeIds.add(ciRecordTypes.get(recTypeName).getRecordTypeId());
            }
            for (PJN_Contact_Information__c contactInfo : (List<PJN_Contact_Information__c>) Trigger.new) {
                if(contactInfo.PJN_Set_as_Relay_Phone__c){
                    if (!phoneRecTypeIds.contains(contactInfo.RecordTypeId)) {
                        contactInfo.addError(notPhoneRelayError);
                    }
                    else if (contactInfo.PJN_Set_as_Relay_Phone__c) {
                        cisToSetAsRelayPhone.add(contactInfo);
                        contactInfo.PJN_Set_as_Relay_Phone__c = false; 
                    }
                }
            }
        } else {
            List<Account> accountsToUpdate = new List<Account>();
            for (PJN_Contact_Information__c contactInfo : cisToSetAsRelayPhone) {
                accountsToUpdate.add(
                    new Account(
                        id = contactInfo.PJN_Account__c,
                        PJN_Relay_Phone__c = contactInfo.id,
                        PJN_Relay_Phone_Number__c = contactInfo.PJN_Value__c
                    )
                );
            }

            update accountsToUpdate;
        }
    }
}