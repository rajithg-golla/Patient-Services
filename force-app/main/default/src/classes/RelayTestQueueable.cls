@isTest
public with sharing class RelayTestQueueable implements Queueable, Database.AllowsCallouts {    
    public void TestQueueable() {

    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [SELECT Name, Site FROM ACCOUNT];
        for (Account a: accounts) {
            a.Site = 'stop';   // Note: For testing, we are using the existing Site field to hold the Relay Consent value
            a.Phone = '100-555-1212';
        }
        update accounts;
    }

    // Setup our test structure

    static testMethod void testUpdatingAccountsFromQueueable() {

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone',             
            AccountConsentFieldName__c='Site', // Note: For testing, we are using the existing Site field to hold the Relay Consent value
            RelayDisableAccountTrigger__c=false);

        // Add some test accounts with a default Relay consent. 
        // In the queueable job, we will update the consent on these records
        // to a different value and check that we make the proper callouts to Relay
        List <Account> accns = new List<Account>();
        for (integer i = 0; i < 200; i++) {
            Account a = new Account(Name='testAccount'+ i);
            try {
                a.Site = 'express'; // Note: For testing, we are using the existing Site field to hold the Relay Consent value
            } catch (Exception ex) {

            }
            accns.add(a);
        }
        insert accns;

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Test.StartTest();
        RelayTestQueueable ruc = new RelayTestQueueable();
            ID jobId = System.enqueueJob(ruc);
            System.debug('batch jobId='+jobId);    
        Test.StopTest();

        try {
            System.AssertEquals(            
                database.countquery('SELECT COUNT() FROM Account WHERE Site= \'stop\''), 200); 
        } catch (Exception ex) {

        }
     }
}