@isTest
public class TestRelayLargeAccountTrigger {
    /*
    ** NOTE:
    ** Because we don't add the Relay fields to the Account object automatically (RelayConsent__c, RelayCCID__c)
    ** For testing we are going to set the configuration to a standard Account field. This will allow the test to
    ** run on a clean org where the custom Relay fields have not been added yet. 
    */

    /*
    ** Trigger multiple Account consent change events
    */
    static testMethod void TestLargeAccountTrigger() {

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone', 
            // Note: We are using the existing Site field to hold the Relay Consent value. This is just for testing
            AccountConsentFieldName__c='Site',          
            RelayDisableAccountTrigger__c=false);

        List<Account> accounts = (List<Account>)new List<Account>();
        for (Integer i = 0; i < 150; i++) {
            Account acct = new Account(Name='Unit Test-'+i, AccountNumber='test-acct-'+i, Phone='1-100-555-1212', Site='Written');
            accounts.add(acct);
        }
        insert accounts;

        for (Integer i = 0; i < 150; i++ ) {
            accounts[i].Site = 'stop';
        }
        Test.startTest();
        upsert accounts;
        Test.stopTest();

        // Verify a batch job was created to process the consent changes
        List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors FROM AsyncApexJob];
        system.assert(jobs.size() == 1);
    }

    static testMethod void TestMobileNumberChange() {

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone', 
            // Note: We are using the existing Site field to hold the Relay Consent value. This is just for testing
            AccountConsentFieldName__c='Site',          
            RelayDisableAccountTrigger__c=false);

        Account acct = new Account(Name='Unit Test', AccountNumber='test-acct', Phone='1-100-555-1111', Site='Written');
        insert acct;

        acct.Phone = '100-555-2222';
        update acct;

        // Verify a batch job was created to process the consent changes
        List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors FROM AsyncApexJob];
        system.assert(jobs.size() == 1);
    }


    /*
    ** Test that no batch job is created
    */
    static testMethod void TestNoBatchJobCreated() {

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone', 
            // Note: In this test we do not map a consent field which will cause the Account trigger to nop
            AccountConsentFieldName__c=null,          
            RelayDisableAccountTrigger__c=false);

        List<Account> accounts = (List<Account>)new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acct = new Account(Name='Unit Test-'+i, AccountNumber='test-acct-'+i, Phone='1-100-555-1212', Site='Written');
            accounts.add(acct);
        }
        insert accounts;

        for (Integer i = 0; i < 5; i++ ) {
            accounts[i].Site = 'stop';
        }
        upsert accounts;

        // Verify a batch job was created to process the consent changes
        List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors FROM AsyncApexJob];
        system.assert(jobs.size() == 0);
    }

    static testMethod void TestDisabledTrigger() {

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

        Relay.testMetaData = new Relay_Network__mdt(
            RelayMobilePhoneFieldName__c='Phone', 
            // Note: In this test we do not map a consent field which will cause the Account trigger to nop
            AccountConsentFieldName__c=null,          
            RelayDisableAccountTrigger__c=true);

        List<Account> accounts = (List<Account>)new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acct = new Account(Name='Unit Test-'+i, AccountNumber='test-acct-'+i, Phone='1-100-555-1212', Site='Written');
            accounts.add(acct);
        }
        insert accounts;

        for (Integer i = 0; i < 5; i++ ) {
            accounts[i].Site = 'stop';
        }
        upsert accounts;

        // Verify a batch job was created to process the consent changes
        List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors FROM AsyncApexJob];
        system.assert(jobs.size() == 0);
    }

    
    // static testMethod void TestAccountTrigger4() {
    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new RelayHttpMock('updateConsent', 'PUT', 200, '{}'));

    //     String testCcid = 'ccid-trigger-4';
    //     String phone = '1005551212';
    //     Account account = new Account(Name='Unit Test', AccountNumber='9999-3', Phone='100-555-1212');
    //     try {
    //         account.put('RelayCCID__c', testCcid);
    //         //account.put('MobilePhone__c', '(100) 555-1212');
    //         account.put('RelayConsent__c','written');
    //     }
    //     catch (Exception ex) {
    //     }

    //     insert account;


    //     // We have to seed the search result otherwise the FIND (in the RelayEventTrigger class) will not find the test row
    //     Id [] fixedSearchResults = new Id[]{account.Id};
    //     Test.setFixedSearchResults(fixedSearchResults);

    //     // Create a RelayEvent to simulate a consent change comming from Relay
    //     String stopConsent = 'Stop';
    //     try {
    //         RelayEvents__c reevt = new RelayEvents__c(EventSubType__c='update', RelayCCID__c=testCcid,
    //                 EventType__c='channel_consent', ChannelAddr__c=phone, SourceChannel__c='sms_conversation', CurrentConsent__c=stopConsent);
    //         insert reevt;
    //     }
    //     catch (Exception ex) {}

    //     // Account matchAccount = [SELECT Id, Name, RelayConsent__c FROM Account WHERE Id = :account.Id limit 1];
    //     // System.assert(matchAccount != null);
    //     // System.assert(stopConsent.equalsIgnoreCase((String)matchAccount.get('RelayConsent__c')));
    //     Test.stopTest();
    // }
}