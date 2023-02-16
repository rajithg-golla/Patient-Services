/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Handle any necessary logic for a Lead that has just been converted
 */
public with sharing class LeadAfterConvertHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {

        // determine if any leads were converted
        List<Lead> convertedLeads = new List<Lead>();
        for (Lead currentLead : (List<Lead>)Trigger.new) {
            Lead oldLead = (Lead) Trigger.oldMap.get(currentLead.Id);
            if (currentLead.ConvertedAccountId != oldLead.ConvertedAccountId ) {
                convertedLeads.add(currentLead);
            }
        }

        // if there were no converted leads then simply exit
        if (convertedLeads.isEmpty()) {
            return;
        }

        createContactInformation( convertedLeads );
    }


    private void createContactInformation(List<Lead> convertedLeads) {
        List<PJN_Contact_Information__c> newContactInfo = new List<PJN_Contact_Information__c>();
        Map<String, RecordTypeInfo> recTypes = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();

        for (Lead convertedLead : convertedLeads) {
            if (String.isNotBlank(convertedLead.Email)) {
                newContactInfo.add(
                    new PJN_Contact_Information__c(
                        PJN_Email__c = convertedLead.Email,
                        PJN_Account__c = convertedLead.ConvertedAccountId,
                        RecordTypeId = recTypes.get('PJN_Email').getRecordTypeId(),
                        PJN_Set_as_Primary__c = true
                    )
                );
            }

            if (String.isNotBlank(convertedLead.Phone)) {
                newContactInfo.add(
                    new PJN_Contact_Information__c(
                        PJN_Phone__c = convertedLead.Phone,
                        PJN_Account__c = convertedLead.ConvertedAccountId,
                        RecordTypeId = recTypes.get('PJN_Phone').getRecordTypeId(),
                        PJN_Set_as_Primary__c = true
                    )
                );
            }

            // don't add country as it is a default value an always there
            Boolean convertAddress = String.isNotBlank(convertedLead.Street)
                || String.isNotBlank(convertedLead.City)
                || String.isNotBlank(convertedLead.State)
                || String.isNotBlank(convertedLead.PostalCode);

            if (convertAddress) {
                newContactInfo.add(
                    new PJN_Contact_Information__c(
                        PJN_Address_Line_1__c = convertedLead.Street,
                        PJN_City__c = convertedLead.City,
                        PJN_State__C = convertedLead.State,
                        PJN_Postal_Code__c = convertedLead.PostalCode,
                        PJN_Country__c = convertedLead.Country,
                        PJN_Account__c = convertedLead.ConvertedAccountId,
                        RecordTypeId = recTypes.get('PJN_Address').getRecordTypeId(),
                        PJN_Set_as_Primary__c = true
                    )
                );
            }
        }

        insert newContactInfo;
    }
}