@isTest
public class TestRelayEventTrigger {

    static testMethod void TestPopulatingContactRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');
        insert newContact;
        RelayEvents__c event = new RelayEvents__c(Name='notification_delivered', RelayCCID__c=newContact.Id);        
        insert event;        
        RelayEvents__c event2 = [SELECT Contact__c from RelayEvents__c where Id = :event.Id];

        System.assert(event2.Contact__c == newContact.Id); // Ensure the Contact__c ref was properly updated
    }

    static testMethod void TestPopulatingBatchContactRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact(FirstName='Test1', LastName='Coverage',  MobilePhone='1-100-555-1111'));
        contacts.add( new Contact(FirstName='Test2', LastName='Coverage',  MobilePhone='100-555-2222'));
        insert contacts;
        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add( new RelayEvents__c(Name='notification_delivered', RelayCCID__c=contacts[0].Id));
        events.add( new RelayEvents__c(Name='notification_delivered', RelayCCID__c=contacts[1].Id));
        insert events;
        List<RelayEvents__c> eventsPost = [SELECT Contact__c from RelayEvents__c where Id in (:events[0].Id, :events[1].Id)];

        System.assert(eventsPost.size() == 2);
        System.assert(eventsPost[0].Contact__c != null); // Ensure the Contact__c ref was properly updated
        System.assert(eventsPost[1].Contact__c != null); // Ensure the Contact__c ref was properly updated
    }

    static testMethod void TestNotPopulatingContactRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c=null,
                RelayEventsContactCCIDFieldName__c=null,
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');
        insert newContact;
        RelayEvents__c event = new RelayEvents__c(Name='notification_delivered', RelayCCID__c=newContact.Id);        
        insert event;        
        RelayEvents__c event2 = [SELECT Contact__c from RelayEvents__c where Id = :event.Id];

        System.assert(event2.Contact__c == null); // Ensure the Contact__c ref was properly updated
    }

    static testMethod void TestPopulatingAccountRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        Account account = new Account(Name='Unit Test', AccountNumber='unit-test');
        insert account;
        RelayEvents__c event = new RelayEvents__c(Name='notification_delivered', RelayCCID__c=account.Id);        
        insert event;
        RelayEvents__c event2 = [SELECT Account__c from RelayEvents__c where Id = :event.Id];
        
        System.assert(event2.Account__c == account.Id);
    }

    static testMethod void TestPopulatingBatchAccountRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        List<Account> accounts = new List<Account>();
        accounts.add( new Account(Name='Unit Test 2', AccountNumber='unit-test-1') );
        accounts.add( new Account(Name='Unit Test 2', AccountNumber='unit-test-2') );
        insert accounts;

        List<RelayEvents__c> events = new List<RelayEvents__c>();
        events.add( new RelayEvents__c(Name='notification_delivered', RelayCCID__c=accounts[0].Id));
        events.add( new RelayEvents__c(Name='notification_delivered', RelayCCID__c=accounts[1].Id));
        insert events;

        // let's see if they RelayEvents__c trigger updated the Account references
        List<RelayEvents__c> eventsPost = [SELECT Account__c from RelayEvents__c where Id in (:events[0].Id, :events[1].Id)];
        
        System.assert(eventsPost.size() == 2);
        System.assert(eventsPost[0].Account__c != null);
        System.assert(eventsPost[1].Account__c != null);
    }

    static testMethod void TestNotPopulatingAccountRef() {

        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c=null,
                RelayEventsContactCCIDFieldName__c=null,
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

        Account account = new Account(Name='Unit Test', AccountNumber='unit-test');
        insert account;
        RelayEvents__c event = new RelayEvents__c(Name='notification_delivered', RelayCCID__c=account.Id);        
        insert event;
        RelayEvents__c event2 = [SELECT Account__c from RelayEvents__c where Id = :event.Id];
        
        System.assert(event2.Account__c == null);
    }

    static testMethod void TestConsentUpdates() {
        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);

          RelayEvents__c event = new RelayEvents__c(Name='channel_consent', EventType__c='channel_consent', EventSubType__c='update', ChannelAddr__c='11005551212', RelayCCID__c='1001');
          insert event;
    }

    static testMethod void TestRelayEventTrigger_Bulkified() {
        Relay.testMetaData = new Relay_Network__mdt(
                RelayDisableEventConsentTrigger__c=false,
                RelayEventsAccountCCIDFieldName__c='Id',
                RelayEventsContactCCIDFieldName__c='Id',
                RelayEventsDisableContactLookup__c=false, 
                RelayEventsDisableAccountLookup__c=false, 
                RelayMobilePhoneFieldName__c='Phone', 
                RelayDisableAccountTrigger__c=false, 
                RelayDisableTaskEventing__c=false);
                
        Datetime dt = Datetime.now();
        List<RelayEvents__c> evts = new List<RelayEvents__c>();
        RelayEvents__c re = new RelayEvents__c(
            Name='Test Trigger 1',
            RelayCCID__c = '3445',
            EventType__c = 'journey_trigger',
            EventTimestamp__c = dt,
            ClientMessageTag__c = '5003j00001rxqH4AAI',
            TriggerID__c = '00000000-0000-0000-0000-000000000000',
            TriggerNickname__c = 'n/a'
        );
        evts.add(re);
        re = new RelayEvents__c(
            Name='Test Trigger 2',        
            RelayCCID__c = '3445',
            EventType__c = 'journey_trigger',
            EventSubtype__c = 'action_test-trigger',
            EventTimestamp__c = dt,
            ClientMessageTag__c = '5003j00001dplmCAAQ',	// case id
            TriggerID__c = '00000000-0000-0000-0000-000000000000',
            TriggerNickname__c = 'n/a'
        );
        evts.add(re);
        insert evts;
    }
}