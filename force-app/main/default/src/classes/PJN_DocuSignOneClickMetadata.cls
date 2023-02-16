/**
 * @author Mavens
 * @date May 2019
 * @description Accessor Class for DocuSign One Click metadata records
 * @group DocuSign One Click
 */
public with sharing class PJN_DocuSignOneClickMetadata {

    /*
    *  @description Given an object type query for all settings for an object
    *  @param - SObjectType - the SObject type to query
    *  @return List<PJN_DocuSign_One_Click_Setting__mdt>
    */
    public List<PJN_DocuSign_One_Click_Setting__mdt> getSettingsForObject(SObjectType objectType) {
        List<PJN_DocuSign_One_Click_Setting__mdt> settings = [
            SELECT
                Id,
                PJN_Additional_Filter_Field__c,
                PJN_Additional_Filter_Value__c,
                PJN_Custom_Contact_Note_Map__c,
                PJN_Custom_Contact_Role_Map__c,
                PJN_Custom_Contact_Type_Map__c,
                PJN_Custom_Email_Message__c,
                PJN_Custom_Email_Subject__c,
                PJN_Custom_Related_Contact_List__c,
                PJN_Load_Attachments__c,
                PJN_Load_Default_Contacts__c,
                PJN_Load_Files__c,
                PJN_One_Click_Options__c,
                PJN_Program__r.DeveloperName,
                PJN_Program_Field__c,
                PJN_Recipient_Routing_Order_Sequential__c,
                PJN_Recipient_Signer_Limit__c,
                PJN_Recipient_Starting_Routing_Order__c,
                PJN_Record_Type__c,
                PJN_Related_Content__c,
                PJN_Template_Name__c,
                PJN_Use_Custom_Recipients__c
            FROM
                PJN_DocuSign_One_Click_Setting__mdt
            WHERE
                PJN_SObject__c = :objectType.getDescribe().getName()
        ];

        return settings;
    }

    /*
    *  @description Given a DocuSign One Click Setting Id, get recipients with their child fields
    *  @param - Id - the Id of the PJN_DocuSign_One_Click_Setting__mdt
    *  @return List<PJN_DocuSign_One_Click_Recipient__mdt>
    */
    public List<PJN_DocuSign_One_Click_Recipient__mdt> getRecipients(String settingId){
        List<PJN_DocuSign_One_Click_Recipient__mdt> recipients = [
            SELECT
                Id,
                PJN_Type__c
            FROM
                PJN_DocuSign_One_Click_Recipient__mdt
            WHERE
                PJN_DocuSign_One_Click_Setting__c = :settingId
        ];

        return recipients;
    }

    /*
    *  @description Given a DocuSign One Click Recipient Id, get recipient fields
    *  @param - Id - the Id of the PJN_DocuSign_One_Click_Recipient__mdt
    *  @return List<PJN_DocuSign_One_Click_Recipient_Field__mdt>
    */
    public List<PJN_DocuSign_One_Click_Recipient_Field__mdt> getRecipientFields(Id recipientConfigId) {
        List<PJN_DocuSign_One_Click_Recipient_Field__mdt> recipientFields = [
            SELECT
                Id,
                PJN_Field__c,
                PJN_Source_Field__c,
                PJN_Value__c
            FROM
                PJN_DocuSign_One_Click_Recipient_Field__mdt
            WHERE
                PJN_DocuSign_One_Click_Recipient__c = :recipientConfigId
        ];

        return recipientFields;
    }
}