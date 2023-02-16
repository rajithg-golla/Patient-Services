@isTest
public class TestRelayExperienceStatus {    

    static void setupMetaData() {
        Relay.testMetaData = new Relay_Network__mdt(
            Client_ID__c='sf-unit=test', 
            API_Key__c='111-222-333', 
            RelayApiUrl__c='https://sf-unit-test.relayit.com',
            RelayDisableEventConsentTrigger__c=false,
            RelayEventsAccountCCIDFieldName__c=null,
            RelayEventsContactCCIDFieldName__c=null,
            RelayEventsDisableContactLookup__c=false, 
            RelayEventsDisableAccountLookup__c=false, 
            RelayMobilePhoneFieldName__c='Phone', 
            RelayDisableAccountTrigger__c=false, 
            RelayDisableTaskEventing__c=false);
    }

    static RelayExperienceStatus getTriggerStats(List<RelayExperienceStatus> stats, String triggerId) {
        for (RelayExperienceStatus stat: stats) {
            if (stat.triggerId == triggerId)
                return stat;
        }
        return null;
    }

    static testmethod void testHappyPath() {
        setupMetaData();

        String ccid = '1001';
        String triggerId1 = 'AAA-BBB-CCC';
        // Add some mock event records
        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add(new RelayEvents__c(name='Sent Experience', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='journey_trigger', EventSubType__c='', ActionValue__c='',
                EventTimestamp__c=Datetime.now()
            ));
        events.add(new RelayEvents__c(name='Message: Added to wire', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='message', EventSubType__c='delivered', ActionValue__c='',
                EventTimestamp__c=Datetime.now().addSeconds(10)
            ));
        events.add(new RelayEvents__c(name='SMS: Delivered', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='notification', EventSubType__c='delivered', ActionValue__c='',
                EventTimestamp__c=Datetime.now().addSeconds(15)
            ));
        events.add(new RelayEvents__c(name='Message: Opened', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='notification', EventSubType__c='auth_link_used', ActionValue__c='',
                EventTimestamp__c=Datetime.now().addSeconds(20)
            ));
        insert events;
        
        List<String> triggerIds = new List<String>();
        triggerIds.add(triggerId1);
        triggerIds.add('DDD-EEE-FFFF');

        List<RelayExperienceStatus> res = RelayExperienceStatus.getExperienceStatus(ccid, triggerIds);
        
        System.assert(res != null);                

        RelayExperienceStatus stats1 = getTriggerStats(res, triggerId1);
        System.assert(stats1 != null);
        System.assert(stats1.requestSentDtm > 0, 'Request Sent DTM not set');
        System.assert(stats1.postedDtm > 0, 'Posted DTM not set');
        System.assert(stats1.deliveredDtm > 0, 'Notification delivered DTM not set');
        System.assert(stats1.openedDtm > 0, 'Opened DTM should be set');
    }

    static testmethod void testDeliveredBeforePosted() {
        setupMetaData();

        String ccid = '1001';
        String triggerId1 = 'AAA-BBB-CCC';
        // Add some mock event records
        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add(new RelayEvents__c(name='SMS: Delivered', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='notification', EventSubType__c='delivered', ActionValue__c='',
                EventTimestamp__c=Datetime.now()
            ));
        events.add(new RelayEvents__c(name='Sent Experience', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='journey_trigger', EventSubType__c='', ActionValue__c='',
                EventTimestamp__c=Datetime.now().addSeconds(10)
            ));
        insert events;
        
        List<String> triggerIds = new List<String>();
        triggerIds.add(triggerId1);
        triggerIds.add('DDD-EEE-FFFF');

        List<RelayExperienceStatus> res = RelayExperienceStatus.getExperienceStatus(ccid, triggerIds);
        
        System.assert(res != null);                

        RelayExperienceStatus stats1 = getTriggerStats(res, triggerId1);
        System.assert(stats1 != null);
        System.assert(stats1.requestSentDtm > 0, 'Request Sent DTM not set');        
        System.assert(stats1.deliveredDtm == 0, 'Notification delivered DTM should be 0');
    }

    static testmethod void testNotPosted() {
        setupMetaData();

        String ccid = '1001';
        String triggerId1 = 'AAA-BBB-CCC';
        String reason = 'Message Suppression';
        // Add some mock event records
        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add(new RelayEvents__c(name='Message: Undelivered', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='message', EventSubType__c='undelivered', ActionValue__c=reason,
                EventTimestamp__c=Datetime.now().addSeconds(10)
            ));
        insert events;
        
        List<String> triggerIds = new List<String>();
        triggerIds.add(triggerId1);

        List<RelayExperienceStatus> res = RelayExperienceStatus.getExperienceStatus(ccid, triggerIds);
        
        System.assert(res != null);                

        RelayExperienceStatus stats1 = getTriggerStats(res, triggerId1);
        System.assert(stats1 != null);
        System.assertEquals(stats1.postedDtm, 0, 'Posted DTM should NOT have been set');
        System.assert(stats1.notPostedDtm > 0, 'Not Posted DTM should have been set');
        System.assertEquals(stats1.notPostedReason, reason, 'Not Posted reason should have been set');
        System.assertEquals(stats1.deliveredDtm, 0, 'Notification delivered DTM should be 0');
    }

    static testmethod void testNotDelivered() {
        setupMetaData();
        
        String ccid = '1001';
        String triggerId1 = 'AAA-BBB-CCC';
        String reason = 'Carrier error';
        // Add some mock event records
        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add(new RelayEvents__c(name='Sent Experience', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='journey_trigger', EventSubType__c='', ActionValue__c='',
                EventTimestamp__c=Datetime.now()
            ));
        events.add(new RelayEvents__c(name='Message: Added to wire', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='message', EventSubType__c='delivered', ActionValue__c='',
                EventTimestamp__c=Datetime.now().addSeconds(10)
            ));
        events.add(new RelayEvents__c(name='SMS: Not Delivered', RelayCCID__c=ccid, TriggerID__c=triggerId1, 
                EventType__c='notification', EventSubType__c='undelivered', ActionValue__c=reason,
                EventTimestamp__c=Datetime.now().addSeconds(15)
            ));
        insert events;
        
        List<String> triggerIds = new List<String>();
        triggerIds.add(triggerId1);

        List<RelayExperienceStatus> res = RelayExperienceStatus.getExperienceStatus(ccid, triggerIds);
        
        System.assert(res != null);                

        RelayExperienceStatus stats1 = getTriggerStats(res, triggerId1);
        System.assert(stats1 != null);
        System.assert(stats1.postedDtm > 0, 'Posted DTM should have been set');
        System.assert(stats1.undeliveredDtm > 0, 'Not Delivered DTM should have been set');
        System.assertEquals(stats1.undeliveredReason, reason, 'Not Delivered reason should have been set');
        System.assertEquals(stats1.deliveredDtm, 0, 'Notification delivered DTM should be 0');
    }
}