@isTest
public class RelayCalloutTest {
    @isTest static void testGetJourneyList() {
        setupMetadata();
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('getJourney', 'GET', 200, '{}'));

        Object res = Relay.getJourneyList(0,3, 'sfdc');
        System.assert(res != null);
    }

    @isTest static void testTriggerJourneyList1() {
        setupMetadata();
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('trigggerJourney', 'POST', 200, '{}'));

        Object res = Relay.triggerJourney('welcome', '1001' , '{}', 'Welcome', 'Contact');
        System.assert(res != null);
    }

    @isTest static void testTriggerJourneyList2() {
        setupMetadata();
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('triggerJourney', 'POST', 200, '{}'));

        Object res = Relay.triggerJourney('welcome', '1001', null, 'Welcome', 'Contact' );
        System.assert(res != null);
    }

    @isTest(SeeAllData=true) static void testGetRelaySettings() {
        setupMetadata();
        Object json = Relay.getRelaySettings();

        System.assert(json != null);
    }

    @isTest static void testLastTriggerDate() {
        setupMetadata();

        Datetime dt = Datetime.now();

        RelayEvents__c re = new RelayEvents__c(
                Name='Experience Sent',
                RelayCCID__c = '1001',
                EventType__c = 'journey_trigger',
                EventTimestamp__c = dt,
                ClientMessageTag__c = '5003j00001bMJuMAAW',
                TriggerID__c = 'Welcome',
                TriggerNickname__c = 'Welcome Test'
        );
        insert re;
        re = new RelayEvents__c(
                Name='Opened SMS',
                RelayCCID__c = '1001',
                EventType__c = 'notification',
                EventSubType__c = 'auth_link_used',
                EventTimestamp__c = dt,
                ClientMessageTag__c = '5003j00001bMJuMAAW',
                TriggerID__c = 'Welcome',
                TriggerNickname__c = 'Welcome Test'
        );
        insert re;

        String jsonstr = Relay.getLastTriggerDate('1001','Welcome');
        Relay.EngagementDates edates = (Relay.EngagementDates)JSON.deserialize(jsonstr, Relay.EngagementDates.class);

        Long tm = dt.GetTime();
        System.debug(tm);
        System.debug(edates.sentDtm);
        System.assert(edates.sentDtm != 0);
        // System.assert(edates.openedDtm != 0);
    }

    static void setupMetadata() {
        Relay.testMetaData = new Relay_Network__mdt(
            RelayDisableEventConsentTrigger__c=false,
            RelayEventsAccountCCIDFieldName__c=null,
            RelayEventsContactCCIDFieldName__c=null,
            RelayEventsDisableContactLookup__c=false, 
            RelayEventsDisableAccountLookup__c=false, 
            RelayMobilePhoneFieldName__c=null, 
            RelayDisableAccountTrigger__c=false, 
            RelayDisableTaskEventing__c=false);
    }
    // @isTest static void testProcessHttpResponse() {
    //     List<String> labels;

    //     Relay.processHttpResponse(labels, state)
    // }
}