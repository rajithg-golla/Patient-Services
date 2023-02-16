@isTest
public class TestRelay {

    // static testMethod void TestRelayContactTrigger() {
    //     Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');
    //     try {
    //         ((SObject)newContact).put('RelayCCID__c', 'unit-test');
    //         ((SObject)newContact).put('RelayConsent__c', 'stop');
    //     } catch (Exception ex) {
    //         System.debug('TestRelayContactTrigger: failed to put custom Relay fields on insert');
    //     }
    //     Insert newContact;

    //     Test.setMock(HttpCalloutMock.class, new RelayHttpMock('update consent', 'PUT', 200, '{}'));

    //     try {
    //         ((SObject)newContact).put('MobilePhone', '1005551414');
    //         ((SObject)newContact).put('RelayConsent__c', 'express');
    //     }
    //     catch (Exception ex) {
    //         System.debug('TestRelayContactTrigger: failed to put customer Relay fields on update');
    //     }
    //     Update newContact;
    // }

    static testMethod void TestCustomerObject() {
        Relay.Customer cust1 = new Relay.Customer('1001', 'John', 'Doe', 'M', DateTime.newInstance(1990,1,1,0,0,0));
    }

    static testMethod void TestConsentUpdate() {
        Relay.ConsentUpdate cu = new Relay.ConsentUpdate('(100) 555-1212', 'stop', 'express');
        System.assert(cu.MobilePhone == '1005551212');
        System.assert(cu.OldConsent == 'express');        
        Relay.ConsentUpdate cu2 = new Relay.ConsentUpdate(null, null, 'STOP');
        System.assert(cu.NewConsent == 'stop');
        Relay.ConsentUpdate cu3 = new Relay.ConsentUpdate(null, 'stop', null);
    }

    static testMethod void TestCreateCustomerOnboard() {
        String triggerId = 'WelcomeTrigger';
        Boolean deactivatePreviousConnections = true;
        Relay.Customer cust = new Relay.Customer('1001-100', 'John', 'Smith', 'M', Datetime.newInstance(1985,1,1));

        Relay.NotificationChannel noti = new Relay.NotificationChannel('1 (215) 555-1212', 'SMS', 'Written');
        System.assert(noti.channel_addr == '12155551212');
        System.assert(noti.channel_type == 'sms');
        System.assert(noti.consent_type == 'written');

        Relay.NotificationChannel noti2 = new Relay.NotificationChannel();
        noti2.channel_addr = '100...555...1212';
        noti2.channel_type = 'SmS';
        noti2.consent_type = 'STOP';
        System.assert(noti2.channel_addr == '1005551212');
        System.assert(noti2.channel_type == 'sms');
        System.assert(noti2.consent_type == 'stop');

        Relay.CustomerOnboard onboard = new Relay.CustomerOnboard(cust,triggerId, deactivatePreviousConnections);
        cust.addNotificationChannel(noti);

        System.assert(onboard.trigger_id == triggerId);
        System.assert(onboard.product_group_id == 'default');
        System.assert(onboard.deactivate_previous_connections == deactivatePreviousConnections);
        Relay.Customer custCheck = onboard.customer;
        System.assert(custCheck.ccid == cust.ccid);
        System.assert(custCheck.first_name == cust.first_name);
        System.assert(custCheck.last_name == cust.last_name);
        System.assert(custCheck.gender == cust.gender);
        System.assert(custCheck.date_of_birth == cust.date_of_birth);

        Relay.CustomerOnboard onboard2 = new Relay.CustomerOnboard();
        System.assert(onboard2.deactivate_previous_connections == true);

    }

    static testMethod void TestCustomerOnboard() {
        String triggerId = 'WelcomeTrigger';
        Boolean deactivatePreviousConnections = true;
        Relay.Customer cust = new Relay.Customer('1001-100', 'John', 'Smith', 'M', Datetime.newInstance(1985,1,1));
        Relay.NotificationChannel noti = new Relay.NotificationChannel('1 (215) 555-1212', 'SMS', 'Written');
        Relay.CustomerOnboard onboard = new Relay.CustomerOnboard(cust,triggerId, deactivatePreviousConnections);
        cust.addNotificationChannel(noti);

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('onboarding','POST', 200, '{}'));
        Object res = Relay.onboardCustomer(onboard, 'Welcome Trigger', 'Account');
        System.assert(res != null);
    }

    static testMethod void TestCreateSingleExperience() {
        String triggerId = 'welcome-trigger';
        String ccid = '1001-100';
        String jsonMatch = '{"trigger_id":"welcome-trigger","input_parameters":{"input_name":"steve"},"ccid":"1001-100"}';
        Relay.SingleExperience si = new Relay.SingleExperience(triggerId, ccid);
        si.addInput('name', 'steve');
        String j = si.getJson();
        System.assert(j == jsonMatch);
    }

    static testMethod void TestCreateBatchExperience() {
        String jsonMatch = '{"batch":[{"trigger_id":"welcome-trigger","input_parameters":{"input_name":"steve"},"ccid":"1001-100"},{"trigger_id":"paperless-trigger","input_parameters":{"input_member_since":"1984"},"ccid":"1001-200"}]}';
        Relay.BatchExperience batch = new Relay.BatchExperience();
        Relay.SingleExperience si1 = new Relay.SingleExperience('welcome-trigger', '1001-100');
        si1.addInput('name', 'steve');
        batch.addSingleExperience(si1);
        Relay.SingleExperience si2 = new Relay.SingleExperience('paperless-trigger', '1001-200');
        si2.addInput('member_since', '1984');
        batch.addSingleExperience(si2);

        String j = batch.getJson();
        System.assert(j == jsonMatch);
    }

    static testMethod void testCreateEngagementDates() {
        Relay.EngagementDates edates = new Relay.EngagementDates();
        System.assert(edates.sentDtm == 0);
        System.assert(edates.openedDtm == 0);
    }

    static testMethod void testGetField() {
        Account acct = new Account(Name='ABC Corp');
        Contact contact = new Contact(Account=acct, FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');

        System.assert(Relay.getField('LastName', contact) == 'Coverage');
        // Test getting child field relationship
        System.assert(Relay.getField('Account.Name', contact) == 'ABC Corp');
    }

    static testMethod void testGetLastTriggerDate() {
        String j = Relay.getLastTriggerDate('bad-ccid', 'welcome-trigger');
        Relay.EngagementDates edates = (Relay.EngagementDates)JSON.deserialize(j, Relay.EngagementDates.class);
        System.assert(edates.sentDtm == 0);
        System.assert(edates.openedDtm == 0);
    }

    static testMethod void testNotificationChannelObject() {
        Relay.NotificationChannel nc = new Relay.NotificationChannel(null,null,null);
        System.assert(nc.channel_addr == '');
        System.assert(nc.channel_type == 'sms');
        System.assert(nc.consent_type == 'stop');
    }

    static testMethod void testGetRelayHttpRequest() {
        HttpRequest hr = Relay.getRelayHttpRequest('GET', 'https://unittesting.nothing', '{}');
        System.assert(hr != null);
    }

    static testMethod void testCreateRealyAddress() {
        Relay.Address addr = new Relay.Address('1 Main Street', 'Media', 'PA', '19063');
        
        System.assert(addr != null);
        System.assert(addr.address1 == '1 Main Street');
        System.assert(addr.city == 'Media');
        System.assert(addr.state_province == 'PA');
        System.assert(addr.postal_code == '19063');
    }

    static testMethod void testUpdateConsentAsync() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('consent-update-async','PUT', 201, '{}'));        
        Relay.updateConsentAsync('test-1001','100-555-0000', 'stop');        
    }

    static testMethod void testUpdateConsentBatchAsyncWithException() {
        
        Test.StartTest();
            Relay.updateConsentBatchAsync('{ bad json}');
        Test.StopTest();            
    }

    static testMethod void testBuildBatchConsentRequest() {
        List<Relay.ConsentUpdate> consentUpdates = new List<Relay.ConsentUpdate>();

        for (Integer i = 0; i < 250; i++) {
            String padid = String.valueOf(i).leftPad(4,'0');            
            String mobilePhone = '100-555-'+padid;
            Relay.ConsentUpdate cu = new Relay.ConsentUpdate(mobilePhone, 'express', 'stop');
            consentUpdates.add(cu);
        }

        String json = Relay.buildConsentUpdateRequest(consentUpdates);
        System.assert(json != null);
        System.debug(json);
        System.assert(consentUpdates.size() == 50);
    }

    static testMethod void testUpdateConsentBatch() {
        List<Relay.ConsentUpdate> consentUpdates = new List<Relay.ConsentUpdate>();

        for (Integer i = 0; i < 10; i++) {
            String padid = String.valueOf(i).leftPad(4,'0');            
            String mobilePhone = '100-555-'+padid;
            Relay.ConsentUpdate cu = new Relay.ConsentUpdate(mobilePhone, 'express', 'stop');
            consentUpdates.add(cu);
        }

        String json = JSON.serialize(consentUpdates);

        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('consent-update-batch-async','PUT', 201, '{}'));
        Relay.updateConsentBatchAsync(json);        
    }

    static testMethod void testGetUpdateConsentHttpRequest() {
        HttpRequest req = Relay.getUpdateConsentHttpRequest('1000', '11005551212', 'stop');
        System.assert(req != null);
        System.assert(req.getBody() == '{ "consent_type" : "stop" }');

    }

    static testMethod void testGetUpdateConsentHttpRequestException() {
        try {
            HttpRequest req = Relay.getUpdateConsentHttpRequest('1000', null, 'stop');
        }
        catch (IllegalArgumentException iae) {
            System.debug(iae);
        }        
    }

    static testMethod void testGetJourneyContinuation() {
        String mockResponseBody = '{ journeys: []}';

        Test.StartTest();

            Continuation con = (Continuation)Relay.getJourneyList(0, 10, 'sfdc');
            Map<String, HttpRequest> requests = con.getRequests();
            System.assertEquals(1, requests.size(), 'The number of Continuation requests is not 1');

            // Setup our mock response
            HttpResponse rsp = new HttpResponse();
            rsp.setStatusCode(200);
            rsp.setBody(mockResponseBody);

            Test.setContinuationResponse(Relay.continuationLabel, rsp);

            String result = (String)Relay.processHttpResponse(
                    new List<String>(requests.keySet()), 
                    Relay.continuationState);

        Test.StopTest();        
        System.assertEquals('{"statusCode":200,"bodyBase64":"eyBqb3VybmV5czogW119","body":null}', result);
    }

    static testMethod void testTriggerJourneyContinuation() {

        Relay.testMetaData = new Relay_Network__mdt(
            RelayDisableEventConsentTrigger__c=true,
            RelayEventsAccountCCIDFieldName__c='Id',
            RelayEventsContactCCIDFieldName__c='Id',
            RelayEventsDisableContactLookup__c=true, 
            RelayEventsDisableAccountLookup__c=true, 
            RelayMobilePhoneFieldName__c='Phone', 
            RelayDisableAccountTrigger__c=true, 
            RelayDisableTaskEventing__c=true);

        String triggerId = 'A001-000-B001';
        String ccid = '1001';
        String body = '{}';
        String triggerNickname = 'Test Trigger';
        String apiName = 'onboarding';

        String mockResponseBody = '{ status: "ok"}';

        Test.StartTest();

            Continuation con = (Continuation)Relay.triggerJourney(triggerId, ccid, body, triggerNickname, apiName);
            Map<String, HttpRequest> requests = con.getRequests();
            System.assertEquals(1, requests.size(), 'The number of Continuation requests is not 1');

            // Setup our mock response
            HttpResponse rsp = new HttpResponse();
            rsp.setStatusCode(200);
            rsp.setBody(mockResponseBody);

            Test.setContinuationResponse(Relay.continuationLabel, rsp);

            String result = (String)Relay.processHttpResponse(
                    new List<String>(requests.keySet()), 
                    Relay.continuationState);

        Test.StopTest();        
        System.assertEquals('{"statusCode":200,"bodyBase64":null,"body":"{ status: \\"ok\\"}"}', 
            result, 'Did not receive expected response body');
        
        RelayEvents__c evt = [SELECT Name, EventType__c, RelayCCID__c, TriggerID__c, TriggerNickname__c 
                FROM RelayEvents__c LIMIT 1];
        System.assert(evt != null, 'RelayEvents__c record was not crated');
        System.assertEquals('Sent Experience', evt.Name, 'Name mismatch');
        System.assertEquals(ccid, evt.RelayCCID__c, 'CCID mismatch');
        System.assertEquals(triggerId, evt.TriggerID__c, 'Trigger ID mismatch');
        System.assertEquals(triggerNickname, evt.TriggerNickname__c, 'Trigger Nickname mismatch');
    }
}