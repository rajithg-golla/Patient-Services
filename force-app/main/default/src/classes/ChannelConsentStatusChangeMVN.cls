/**
 * @author Mavens
 * @date Jul 20, 2020
 * @description Handle status changes for Channel Consent records (i.e. Marketing Cloud status update). 
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ChannelConsentStatusChangeMVN implements TriggerHandlerMVN.HandlerInterface {

    public static final Integer BATCH_THRESHHOLD = 20;

    public void handle() {
        Boolean canCallFuture = !System.isFuture() && !System.isBatch() && !System.isQueueable() && !System.isScheduled();

        if (Trigger.isInsert) {
            List<String> channelConsentIds = new List<String>();
            List<PJN_Channel_Consent__c> newChannelConsents = (List<PJN_Channel_Consent__c>) Trigger.new;

            if (newChannelConsents.size() < ChannelConsentStatusChangeMVN.BATCH_THRESHHOLD && canCallFuture) {
                for (PJN_Channel_Consent__c newChannelConsent : newChannelConsents) {
                    channelConsentIds.add(newChannelConsent.Id);
                }

                MarketingCloudSubscriberUpdateMVN.updateMarketingCloudSubscriberStatusFuture(channelConsentIds);
            } else {
                List<PJN_Channel_Consent__c> channelConsentsToUpdate = new List<PJN_Channel_Consent__c>();
                for (PJN_Channel_Consent__c newChannelConsent : newChannelConsents) {
                    channelConsentsToUpdate.add(new PJN_Channel_Consent__c(
                        Id = newChannelConsent.Id,
                        Pending_Consent_Status_Batch_MVN__c = true
                    ));
                }

                update channelConsentsToUpdate;
            }
        } else if (Trigger.isUpdate) {
            Map<Id,PJN_Channel_Consent__c> oldChannelConsentMap = (Map<Id,PJN_Channel_Consent__c>) Trigger.oldMap;
            Map<Id,PJN_Channel_Consent__c> newChannelConsentMap = (Map<Id,PJN_Channel_Consent__c>) Trigger.newMap;

            List<PJN_Channel_Consent__c> channelConsentsToProcess = new List<PJN_Channel_Consent__c>();
            for (Id channelConsentId : newChannelConsentMap.keySet()) {
                PJN_Channel_Consent__c oldChannelConsent = oldChannelConsentMap.get(channelConsentId);
                PJN_Channel_Consent__c newChannelConsent = newChannelConsentMap.get(channelConsentId);

                // Has Status changed on Channel Consent?
                if (! newChannelConsent.PJN_Privacy_Consent_Status__c.equals(oldChannelConsent.PJN_Privacy_Consent_Status__c)) {
                    channelConsentsToProcess.add(newChannelConsent);
                }
            }

            List<String> channelConsentIds = new List<String>();
            if (!channelConsentsToProcess.isEmpty()) {
                if (channelConsentsToProcess.size() < ChannelConsentStatusChangeMVN.BATCH_THRESHHOLD && canCallFuture) {
                    for (PJN_Channel_Consent__c channelConsentToProcess : channelConsentsToProcess) {
                        channelConsentIds.add(channelConsentToProcess.Id);
                    }
                    MarketingCloudSubscriberUpdateMVN.updateMarketingCloudSubscriberStatusFuture(channelConsentIds);
                } else {
                    List<PJN_Channel_Consent__c> channelConsentsToUpdate = new List<PJN_Channel_Consent__c>();
                    for (PJN_Channel_Consent__c channelConsentToProcess : channelConsentsToProcess) {
                        channelConsentsToUpdate.add(new PJN_Channel_Consent__c(
                            Id = channelConsentToProcess.Id,
                            Pending_Consent_Status_Batch_MVN__c = true
                        ));
                    }

                    update channelConsentsToUpdate;
                }
            } else {
                System.debug(LoggingLevel.DEBUG, 'channelConsentsToUpdate empty, not channel consents to update in marketing cloud');
            }
        }
    }
}