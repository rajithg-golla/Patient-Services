@isTest
public class TestRelayTaskTrigger {
    static testMethod void TestRelayTaskTrigger() {
        Relay.testMetaData = new Relay_Network__mdt(
            RelayDisableEventConsentTrigger__c=false,
            RelayEventsAccountCCIDFieldName__c='Id',
            RelayEventsContactCCIDFieldName__c='Id',
            RelayEventsDisableContactLookup__c=false, 
            RelayEventsDisableAccountLookup__c=false, 
            RelayMobilePhoneFieldName__c='Phone', 
            RelayDisableAccountTrigger__c=false, 
            RelayDisableTaskEventing__c=false);

        Task t = new Task(Subject='call ended');
        insert t;
    }
}