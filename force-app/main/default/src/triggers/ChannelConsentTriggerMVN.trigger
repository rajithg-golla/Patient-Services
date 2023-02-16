trigger ChannelConsentTriggerMVN on PJN_Channel_Consent__c (after insert, after update) {
    new TriggerHandlerMVN()
        .bind(TriggerHandlerMVN.Evt.afterinsert, new ChannelConsentStatusChangeMVN())
        .bind(TriggerHandlerMVN.Evt.afterupdate, new ChannelConsentStatusChangeMVN())
        .manage();
}