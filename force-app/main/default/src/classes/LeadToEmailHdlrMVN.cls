/**
 * @author      Mavens
 * @description Fax Lead to Lash.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LeadToEmailHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        // determine if leads need emails and build id list
        Set<Id> leadIdSet = new Set<Id>();
        List<echosign_dev1__SIGN_Agreement__c> qualifiedAgreements = new List<echosign_dev1__SIGN_Agreement__c>();
        for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>) Trigger.new) {
            if (agreement.CustomConsumer__c != NULL) {
                leadIdSet.add(agreement.CustomConsumer__c);
            }
        }

        if (leadIdSet.size() > 0) {
            List<Lead> leads = queryLeads(leadIdSet);
            List<Id> qualifiedLeadIds = new List<Id>();
            for (Lead consumer : leads) {
                if (isQualifiedForFaxToLash(consumer)) {
                    for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>) Trigger.new) {
                        echosign_dev1__SIGN_Agreement__c oldAgreement;
                        if (Trigger.isUpdate) {
                            oldAgreement = (echosign_dev1__SIGN_Agreement__c) trigger.oldMap.get(agreement.Id);
                        }

                        Boolean leadLookupUpdated = Trigger.isInsert || (Trigger.isUpdate && oldAgreement.CustomConsumer__c != agreement.CustomConsumer__c);

                        if (agreement.CustomConsumer__c == consumer.Id && leadLookupUpdated) {
                            qualifiedAgreements.add(agreement);
                        }
                    }
                }
            }

            // pass lead ids to send emails.
            sendEmails(qualifiedAgreements);
        }
    }

    private static void sendEmails(List<echosign_dev1__SIGN_Agreement__c> agreements) {


        // Set the recipient addresses
        List<Lead_Send_Fax_to_Lash_Setting_MVN__mdt> sendFaxToLashSettings = querySendFaxToLashSettings();
        List<String> recipients = getRecipients(sendFaxToLashSettings);
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = queryEmailTemplate();
        Map<Id, List<Messaging.EmailFileAttachment>> fileMap = getAttachmentMap(agreements);
        OrgWideEmailAddress orgWideEmailAddress = queryOrgWideEmailAddress();

        for (echosign_dev1__SIGN_Agreement__c agreement : agreements) {
            Id leadId = agreement.CustomConsumer__c;
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            
            // Attach files to the message
            message.setFileAttachments(fileMap.get(leadId));

            // Set the message template
            message.setTemplateId(template.Id);
            message.setTargetObjectId(leadId);

            // set the addresses
            message.setToAddresses(recipients);
            message.setTreatTargetObjectAsRecipient(false);

            // Set the message sender address
            message.setOrgWideEmailAddressId(orgWideEmailAddress.Id);

            // Don't save the message as activity
            message.setSaveAsActivity(false);

            messages.add(message);
        }

        // Send the message
        try {
            Messaging.sendEmail(messages);
        } catch (Exception e) {
            throw e;
        }
    }

    private static Map<Id, List<Messaging.EmailFileAttachment>> getAttachmentMap(List<echosign_dev1__SIGN_Agreement__c> agreements) {
        Map<Id, List<Messaging.EmailFileAttachment>> result = new Map<Id, List<Messaging.EmailFileAttachment>>();
        Map<Id, Id> agreementIdToLeadIdMap = new Map<Id, Id>();

        for (echosign_dev1__SIGN_Agreement__c agreement : agreements) {
            agreementIdToLeadIdMap.put(agreement.Id, agreement.CustomConsumer__c);
        }

        for (Attachment file : queryAttachments(agreementIdToLeadIdMap.keySet())) {
            Id leadId = agreementIdToLeadIdMap.get(file.ParentId);
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            String fileName = file.Name;
            efa.setFileName(fileName.right(4) == '.pdf' ? fileName : fileName + '.pdf');
            efa.setBody(file.Body);
            efa.setContentType('application/pdf');

            if (result.containsKey(leadId)) {
                List<Messaging.EmailFileAttachment> fileList = result.get(leadId);
                fileList.add(efa);
                result.put(leadId, fileList);
            } else {
                result.put(leadId, new List<Messaging.EmailFileAttachment>{efa});
            }
        }

        return result;
    }

    private static List<String> getRecipients(List<Lead_Send_Fax_to_Lash_Setting_MVN__mdt> settings) {
        List<String> result = new List<String>();
        for (Lead_Send_Fax_to_Lash_Setting_MVN__mdt setting : settings) {
            result.add(setting.Email_Recipient_MVN__c);
        }
        return result;
    }

    private static Boolean isQualifiedForFaxToLash(Lead consumer) {
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Libtayo Marketing Consumer').getRecordTypeId();

        return (
            consumer.Enrollment_Type_MVN__c == 'Patient' &&
            consumer.RecordTypeId == recordTypeId &&
            consumer.LeadSource == 'Website' &&
            consumer.Qualification_Status_MVN__c == 'Qualified'
        );
    }

    private static List<Attachment> queryAttachments(Set<Id> leadIds) {
        return [SELECT Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId IN :leadIds];
    }

    private static List<Lead> queryLeads(Set<Id> leadIds) {
        return [SELECT Enrollment_Type_MVN__c, RecordTypeId, LeadSource, Qualification_Status_MVN__c FROM Lead WHERE Id IN :leadIds];
    }

    private static List<Lead_Send_Fax_to_Lash_Setting_MVN__mdt> querySendFaxToLashSettings() {
        return [SELECT Email_Recipient_MVN__c FROM Lead_Send_Fax_to_Lash_Setting_MVN__mdt WHERE Active_MVN__c = true];
    }

    private static OrgWideEmailAddress queryOrgWideEmailAddress() {
        return [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Regeneron' LIMIT 1][0];
    }

    private static EmailTemplate queryEmailTemplate() {
        return [SELECT Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Fax_Qualified_Enrollment_to_Lash_MVN' LIMIT 1][0];
    }
}