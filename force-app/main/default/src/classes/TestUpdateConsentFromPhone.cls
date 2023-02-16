@isTest
global class TestUpdateConsentFromPhone {

    static Boolean VerifyAccountField() {
        Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet();
        for (String f : accountFields) {
            if (f.toLowerCase() == 'site') {                
                return true;                
            }
        }
        return false;
    }

    static testMethod void testConsentUpdateJob() {

        if (!VerifyAccountField()) {
            system.debug('Account does not have default Site filed. Skipping test');
            return;
        }
    
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone', 
            // Note: We are using the existing Site field to hold the Relay Consent value. This is just for testing
            AccountConsentFieldName__c='Site',          
            RelayDisableAccountTrigger__c=false);

        // Insert some test Account records
        Integer NumberofAccounts = 5;
        List<Account> accounts = (List<Account>)new List<Account>();
        List<Relay.ConsentUpdate> batchUpdate = new List<Relay.ConsentUpdate>();

        for (Integer i = 0; i < NumberofAccounts; i++) {
            String pn = '1-100-'+String.valueOf(i).leftPad(3,'0')+'-1111';
            Account acct = new Account(Name='Unit Test-'+i, AccountNumber='test-acct-'+i, Phone=pn, Site='Written');
            accounts.add(acct);
            batchUpdate.add(new Relay.ConsentUpdate(pn, 'STOP', 'WRITTEN'));
        }
        insert accounts;

        // Make sure the FIND SOSL (called in the Batch processing) returns some ids
        List<Id> fixedSearchResults = new List<Id>();
        for (Account acct: accounts) {
            fixedSearchResults.add(acct.Id);
        }
        Test.setFixedSearchResults(fixedSearchResults);

        // for (Integer i = 0; i < NumberofAccounts; i++ ) {
        //     accounts[i].Phone = '1-100-'+String.valueOf(i).leftPad(3,'0')+'-2222';
        // }
        // Test.startTest();
        // upsert accounts;
        // Test.stopTest();

        Test.StartTest();
            RelayUpdateConsentFromPhone job = new RelayUpdateConsentFromPhone(batchUpdate);
            ID jobId = System.enqueueJob(job);
        Test.StopTest();    // this will ensure the async batch job is completed

        System.debug('batch consent by phone update jobId='+jobId);

        Account acctVerify = [SELECT Name,Site FROM Account where AccountNumber = 'test-acct-1'];            
        System.assert(acctVerify != null);
        System.assert(acctVerify.Site == 'STOP');

        acctVerify = [SELECT Name,Site FROM Account where AccountNumber = 'test-acct-2'];
        System.assert(acctVerify != null);
        System.assert(acctVerify.Site == 'STOP');
    }
}