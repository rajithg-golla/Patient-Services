/**
 * @author Mavens
 * @date Jul 20, 2020
 * @description Batch process to update Marketing Cloud using Channel Consent
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class ChannelConsentStatusBatchMVN implements
    Database.Batchable<sObject>,
    Database.Stateful,
    Database.AllowsCallouts,
    Schedulable
{
    private List<Exception> errors = new List<Exception>();

    public void execute(SchedulableContext sc) {
        ChannelConsentStatusBatchMVN channelConsentStatusBatch = new ChannelConsentStatusBatchMVN();
        database.executebatch(channelConsentStatusBatch, 50);
    }

    global ChannelConsentStatusBatchMVN() {} // NOPMD 

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            ' SELECT PJN_Contact_Information__c, ' +
            '        PJN_Privacy_Consent_Status__c, ' +
            '        Pending_Consent_Status_Batch_MVN__c ' +
            '   FROM PJN_Channel_Consent__c ' +
            '  WHERE Pending_Consent_Status_Batch_MVN__c = true'
        );
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<PJN_Channel_Consent__c> channelConsents = (List<PJN_Channel_Consent__c>) scope;
            new MarketingCloudSubscriberUpdateMVN().updateMarketingCloudSubscriberStatus(channelConsents);
        } catch (Exception ex) {
            errors.add(ex);
        }
    }

    global void finish(Database.BatchableContext bc) {
        if(!errors.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Errors occurred during Marketing Cloud Subscriber Update process.');
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSaveAsActivity(false);
            String body = 'Errors \n';
            for(Exception e : errors) {
                body += '-' + e.getMessage() + '<br>';
                body += e.getStackTraceString() + '<br>';
            }
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.Email[] { mail });
        }
    }

    global static void start() {
        System.schedule('Marketing Cloud API job (ChannelConsentStatusBatchMVN) at top of hour', '0 0 * * * ?', new ChannelConsentStatusBatchMVN());
        System.schedule('Marketing Cloud API job (ChannelConsentStatusBatchMVN) at 15 minutes', '0 15 * * * ?', new ChannelConsentStatusBatchMVN());
        System.schedule('Marketing Cloud API job (ChannelConsentStatusBatchMVN) at 30 minutes', '0 30 * * * ?', new ChannelConsentStatusBatchMVN());
        System.schedule('Marketing Cloud API job (ChannelConsentStatusBatchMVN) at 45 minutes', '0 45 * * * ?', new ChannelConsentStatusBatchMVN());
    }
}