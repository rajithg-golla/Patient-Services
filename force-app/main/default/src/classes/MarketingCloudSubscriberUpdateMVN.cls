/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description Update Marketing Cloud using Channel Consent
 */
public with sharing class MarketingCloudSubscriberUpdateMVN {

    public static final String CHANNEL_CONSENT_OPT_IN = 'Opt In';
    public static final String CHANNEL_CONSENT_OPT_OUT = 'Opt Out';
    public static final String CONTACT_INFO_EMAIL_RECORD_TYPE = 'PJN_Email';
    public static final String MARKETING_CLOUD_ACTIVE = 'Active';
    public static final String MARKETING_CLOUD_UNSUBSCRIBED = 'Unsubscribed';

    public MarketingCloudSubscriberUpdateMVN() {}

    @future(callout=true)
    public static void updateMarketingCloudSubscriberStatusFuture(List<String> channelConsentsIds) {
        List<PJN_Channel_Consent__c> channelConsents = [
            SELECT PJN_Contact_Information__c,
                   PJN_Privacy_Consent_Status__c,
                   Pending_Consent_Status_Batch_MVN__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :channelConsentsIds
        ];
        new MarketingCloudSubscriberUpdateMVN().updateMarketingCloudSubscriberStatus(channelConsents);
    }

    /*
     * public void updateMarketingCloudSubscriberStatus(List<PJN_Channel_Consent__c> channelConsents)
     * Updates status in Marketing Cloud using Privacy Consent Status on the Channel Consent record.
     * Updates Channel Consent record with results from Marketing Cloud.
     */
    public void updateMarketingCloudSubscriberStatus(List<PJN_Channel_Consent__c> channelConsents) {

        Map<Id, PJN_Channel_Consent__c> channelConsentsById = getChannelConsentsById(channelConsents);
        Map<Id, Map<String, String>> valueMapByChannelConsentId = getSubscriberKeysByChannelConsentId(channelConsents);
        Map<String, Map<String, String>> valueMapBySubscriberKey = new Map<String, Map<String, String>>();

        Map<String,String> subscriberUpdateResultsBySubscriberKey = null;

        if (!valueMapByChannelConsentId.isEmpty()) {
            Map<String,String> subscriberStatus = new Map<String,String>();
            for (Id channelConsentId : valueMapByChannelConsentId.keySet()) {
                Map<String, String> valueMap = valueMapByChannelConsentId.get(channelConsentId);
                PJN_Channel_Consent__c channelConsent = channelConsentsById.get(channelConsentId);
                String status = '';
                if (MarketingCloudSubscriberUpdateMVN.CHANNEL_CONSENT_OPT_IN.equals(channelConsent.PJN_Privacy_Consent_Status__c)) {
                    status = MarketingCloudSubscriberUpdateMVN.MARKETING_CLOUD_ACTIVE;
                } else if (MarketingCloudSubscriberUpdateMVN.CHANNEL_CONSENT_OPT_OUT.equals(channelConsent.PJN_Privacy_Consent_Status__c)) {
                    status = MarketingCloudSubscriberUpdateMVN.MARKETING_CLOUD_UNSUBSCRIBED;
                }
                valueMap.put('Status', status);

                valueMapBySubscriberKey.put(valueMap.get('SubscriberKey'), valueMap);
            }

            MarketingCloudSoapAPIMVN api = new MarketingCloudSoapAPIMVN();
            subscriberUpdateResultsBySubscriberKey = api.updateSubscribersStatus(valueMapBySubscriberKey);
        }

        updateChannelConsents(channelConsentsById, valueMapByChannelConsentId, subscriberUpdateResultsBySubscriberKey);
    }

    private Map<Id,PJN_Channel_Consent__c> getChannelConsentsById(List<PJN_Channel_Consent__c> channelConsents) {
        Map<Id,PJN_Channel_Consent__c> channelConsentsById = new Map<Id,PJN_Channel_Consent__c>();

        for (PJN_Channel_Consent__c channelConsent : channelConsents) {
            channelConsentsById.put(channelConsent.Id, channelConsent);
        }

        return channelConsentsById;
    }

    /*
     * private Map<String, PJN_Channel_Consent__c> getChannelConsentBySubscriberKey(List<PJN_Channel_Consent__c> channelConsents)
     * Returns a map of channel consent indexed by subscriber key (PersonContactId on grandparent account)
     */
    private Map<Id, Map<String, String>> getSubscriberKeysByChannelConsentId(List<PJN_Channel_Consent__c> channelConsents) {
        Map<Id, Map<String, String>> valueMapByChannelConsentId = new Map<Id, Map<String, String>>();

        Set<Id> contactInformationIds = new Set<Id>();
        for (PJN_Channel_Consent__c channelConsent : channelConsents) {
            contactInformationIds.add(channelConsent.PJN_Contact_Information__c);
        }

        Map<Id,PJN_Contact_Information__c> contactInformationsMap = new Map<Id,PJN_Contact_Information__c>([
            SELECT PJN_Account__r.PersonContactId,
                   PJN_Email__c
              FROM PJN_Contact_Information__c
             WHERE Id IN :contactInformationIds
               AND PJN_Primary__c = true
               AND RecordType.DeveloperName = :MarketingCloudSubscriberUpdateMVN.CONTACT_INFO_EMAIL_RECORD_TYPE
        ]);

        for (PJN_Channel_Consent__c channelConsent : channelConsents) {
            if (contactInformationsMap.containsKey(channelConsent.PJN_Contact_Information__c)) {
                Map<String, String> valueMap = new Map<String, String>();
                PJN_Contact_Information__c contactInformation = contactInformationsMap.get(channelConsent.PJN_Contact_Information__c);

                valueMap.put('SubscriberKey', contactInformation.PJN_Account__r.PersonContactId);
                if (contactInformation.PJN_Email__c != NULL) {
                    valueMap.put('EmailAddress', contactInformation.PJN_Email__c);
                }

                valueMapByChannelConsentId.put(channelConsent.Id, valueMap);
            }
        }

        return valueMapByChannelConsentId;
    }

    private static void updateChannelConsents(
        Map<Id, PJN_Channel_Consent__c> channelConsentsById,
        Map<Id, Map<String, String>> valueMapByChannelConsentId,
        Map<String,String> subscriberUpdateResultsBySubscriberKey
    ) {
        Map<Id,PJN_Channel_Consent__c> channelConsentToUpdateMap = new Map<Id,PJN_Channel_Consent__c>([
            SELECT Latest_Marketing_Cloud_API_Status_MVN__c,
                   Pending_Consent_Status_Batch_MVN__c,
                   PJN_Privacy_Consent_Status__c
              FROM PJN_Channel_Consent__c
             WHERE Id IN :channelConsentsById.keySet()
        ]);

        List<PJN_Channel_Consent__c> channelConsentsToUpdate = new List<PJN_Channel_Consent__c>();

        for (Id channelConsentId : channelConsentToUpdateMap.keySet()) {
            Boolean shouldUpdate = false;
            PJN_Channel_Consent__c channelConsentToUpdate = channelConsentToUpdateMap.get(channelConsentId);

            if(valueMapByChannelConsentId.containsKey(channelConsentId)) {
                String subscriberKey = valueMapByChannelConsentId.get(channelConsentId).get('SubscriberKey');
                String subscriberUpdateResult = subscriberUpdateResultsBySubscriberKey.get(subscriberKey);
                channelConsentToUpdate.Latest_Marketing_Cloud_API_Status_MVN__c = subscriberUpdateResult;

                shouldUpdate = true;
            }


            if(channelConsentToUpdate.Pending_Consent_Status_Batch_MVN__c == true) {
                channelConsentToUpdate.Pending_Consent_Status_Batch_MVN__c = false;

                shouldUpdate = true;
            }

            if(shouldUpdate) {
                channelConsentsToUpdate.add(channelConsentToUpdate);
            }
        }

        if(!channelConsentsToUpdate.isEmpty()) {
            update channelConsentsToUpdate;
        }
    }

}