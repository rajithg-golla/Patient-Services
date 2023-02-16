/**
 * @author      Mavens
 * @group       EmailQuickSend
 * @description Upon insert of a Email Quick Send Object pull the template and attachments and send the email.
 */
public with sharing class EmailQuickSendHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {

    @TestVisible
    private static Boolean sendEmails = true;

    public void handle() {
        Map<Id, List<String>> emailToAttachmentDocuments = mapEmailsToAttachments();
        Map<String, Id> documentIdsByNames = getDocumentIdsByDevName(emailToAttachmentDocuments);
        Map<Id, List<Id>> emailToAttachmentDocumentIds = mapAttachmentDocumentIds(emailToAttachmentDocuments, documentIdsByNames);

        List<Messaging.SingleEmailMessage> emailsToSend = createEmails(emailToAttachmentDocumentIds);
        if (sendEmails) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    /*
     * Split out attachments from picklist values and map document names to email records
     */
    private Map<Id, List<String>> mapEmailsToAttachments() {
        Map<Id, List<String>> emailIdsToAttachments = new Map<Id, List<String>>();

        for (Email_Quick_Send_MVN__c quickSend : (List<Email_Quick_Send_MVN__c>) Trigger.new) {
            List<String> attachments = new List<String>();
            if (String.isNotBlank(quickSend.Attachments_MVN__c)) {
                attachments = quickSend.Attachments_MVN__c.split(';');
            }
            emailIdsToAttachments.put(quickSend.Id, attachments);
        }

        return emailIdsToAttachments;
    }

    /*
     * query documents for documents by name
     */
    private Map<String, Id> getDocumentIdsByDevName(Map<Id, List<String>> emailToAttachmentDocuments) {
        Set<String> documentDeveloperNames = new Set<String>();
        for (List<String> documents : emailToAttachmentDocuments.values()) {
            documentDeveloperNames.addAll(documents);
        }

        Map<String, Id> documentsByDevName = new Map<String, Id>();
        for (Document doc : [SELECT Id, DeveloperName FROM Document WHERE DeveloperName IN :documentDeveloperNames]) {
            documentsByDevName.put(doc.DeveloperName, doc.Id);
        }
        return documentsByDevName;
    }

    /*
     * create map of email quick send to document id attachments
     */
    private Map<Id, List<Id>> mapAttachmentDocumentIds(Map<Id, List<String>> emailToAttachmentDocuments, Map<String, Id> documentIdsByNames) {
        Map<Id, List<Id>> emailToAttachmentIds = new Map<Id, List<Id>>();
        for (Id quickSendId : emailToAttachmentDocuments.keySet()) {
            List<Id> docIds = new List<Id>();
            emailToAttachmentIds.put(quickSendId, new List<Id>());
            for (String docName :  emailToAttachmentDocuments.get(quickSendId)) {
                emailToAttachmentIds.get(quickSendId).add(documentIdsByNames.get(docName));
            }
        }
        return emailToAttachmentIds;
    }

    /*
     * generate emails to send
     */
    private List<Messaging.SingleEmailMessage> createEmails( Map<Id, List<Id>> emailToAttachmentDocIds) {
        List<Email_Quick_Send_MVN__c> quickSends = [
            SELECT
                Account_MVN__c,
                Account_MVN__r.PersonContactId,
                Consumer_MVN__c,
                Email_Template_MVN__c,
                To_Address_MVN__c,
                From_Address_MVN__c
            FROM
                Email_Quick_Send_MVN__c
            WHERE
                Id IN :Trigger.new
        ];

        Map<String, Id> templateIdsByName = new Map<String, Id>();
        for (EmailTemplate template : [SELECT Id, DeveloperName FROM EmailTemplate]) {
            templateIdsByName.put(template.DeveloperName, template.Id);
        }

        Map<String, Id> orgWideEmailAddressIdsByName = new Map<String, Id>();
        for (OrgWideEmailAddress address : [SELECT Id, DisplayName FROM OrgWideEmailAddress]) {
            orgWideEmailAddressIdsByName.put(address.DisplayName, address.Id);
        }

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress[] owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='Regeneron' LIMIT 1];
        for (Email_Quick_Send_MVN__c quickSend : quickSends) {
            Messaging.SingleEmailMessage newMessage = new Messaging.SingleEmailMessage();
            if (quickSend.Account_MVN__c != null && String.isNotBlank(quickSend.Account_MVN__r.PersonContactId)) {
                newMessage.setTargetObjectId(quickSend.Account_MVN__r.PersonContactId);
            } else if (String.isNotBlank(quickSend.Consumer_MVN__c)) {
               newMessage.setTargetObjectId(quickSend.Consumer_MVN__c);
            } else {
                continue; // nobody to send to
            }

            newMessage.setTreatTargetObjectAsRecipient(false);
            newMessage.setToAddresses(new List<String>{ quickSend.To_Address_MVN__c });
            if(owea != null &&  owea.size() > 0){
                newMessage.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            else{
                newMessage.setOrgWideEmailAddressId(orgWideEmailAddressIdsByName.get(quickSend.From_Address_MVN__c));
            }
            newMessage.setTemplateId(templateIdsByName.get(quickSend.Email_Template_MVN__c));
            newMessage.setEntityAttachments(emailToAttachmentDocIds.get(quickSend.Id));
            emailMessages.add(newMessage);
        }

        return emailMessages;
    }
}