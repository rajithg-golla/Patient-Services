@isTest
global class testBatchUpdates implements Database.Batchable<sObject> {
    global testBatchUpdates() {
    }

    global Database.querylocator start(Database.BatchableContext BC) {        
////        return Database.getQueryLocator('SELECT id, Name, RelayConsent__c from ACCOUNT WHERE RelayConsent__c != null');
       return Database.getQueryLocator('SELECT id, Name from ACCOUNT');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Account> accns = new List<Account>();
        for (sObject s : scope) {
            Account a = (Account)s;
            System.debug(a);
            try {
                a.Site = 'stop';
                a.Phone = '100-555-1212';
            }
            catch (Exception ex) {

            }
            accns.add(a);
        }        
        update accns;
    }
        
    global void finish(Database.BatchableContext BC) {
    }

    static testMethod void testBatchUpdate() {
        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone',             
            AccountConsentFieldName__c='Site', // Note: For testing, we are using the existing Site field to hold the Relay Consent value
            RelayDisableAccountTrigger__c=false);

        List <Account> accns = new List<Account>();
        for (integer i = 0; i<200; i++) {
            Account a = new Account(Name='testAccount'+ i);
            try {
                a.Site = 'express';
            } catch (Exception ex) {

            }
            accns.add(a);
        }
        insert accns;

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Test.StartTest();
        testBatchUpdates tbu = new testBatchUpdates();
        Database.executeBatch(tbu);
        Test.StopTest();

        try {
            System.AssertEquals(            
                database.countquery('SELECT COUNT() FROM Account WHERE Site= \'stop\''), 200); 
        } catch (Exception ex) {

        }
     }

    static testMethod void testConsentUpdateJob() {
        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone',             
            AccountConsentFieldName__c='Site', // Note: For testing, we are using the existing Site field to hold the Relay Consent value
            RelayDisableAccountTrigger__c=false);

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        List<Relay.ConsentUpdate> batchUpdate = new List<Relay.ConsentUpdate>();
        batchUpdate.add(new Relay.ConsentUpdate( '1005551111', 'STOP', 'WRITTEN'));
        batchUpdate.add(new Relay.ConsentUpdate( '1005552222', 'STOP', 'EXPRESS'));        

        RelayUpdateConsent ruc = new RelayUpdateConsent(batchUpdate);
        ID jobId = System.enqueueJob(ruc);
        System.debug('batch jobId='+jobId);        
    }
}