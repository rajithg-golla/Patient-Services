@isTest
public class TestOnboardingAction {

    static List<Contact> insertTestContacts() {
        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact(FirstName='Test', LastName='Two',  MobilePhone='1005552222', Title='Sr Developer') );
        Insert contacts[0];
        contacts.add( new Contact(FirstName='Test', LastName='One',  MobilePhone='1005551111', Title='Developer', ReportsToId=contacts[0].id) );
        Insert contacts[1];
        return contacts;        
    }

    static testMethod void TestOnboardingWithoutFuture() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));
        List<Contact> contacts = insertTestContacts();
        Contact contact = contacts[0];
        List<RelayOnboardingRequest> batch = new List<RelayOnboardingRequest>();

        RelayOnboardingRequest req = new RelayOnboardingRequest();
        req.id = contact.ID;
        req.FirstName = contact.FirstName;
        req.LastName = contact.LastName;
        req.secondaryAccountId = '000-111-222';
        req.address1 = '1 Main Street';
        req.city = 'Media';
        req.state_province = 'PA';
        req.postal_code = '19063';
        req.ccid = '1001';
        batch.add(req);

        List<RelayDynamicInput> dinputs = new List<RelayDynamicInput>();
        RelayDynamicInput rdi = new RelayDynamicInput();
        rdi.inputName = 'dob';
        rdi.inputValue = '1970-01-01';
        dinputs.add(rdi);

        List<RelayDynamicInput> extdata = new List<RelayDynamicInput>();
        RelayDynamicInput ext = new RelayDynamicInput();
        ext.inputName = 'RepName';
        ext.inputValue = 'Henry';
        extdata.add(ext);

        RelayOnboardActionRequest actionReq = new RelayOnboardActionRequest();
        actionReq.batchRequest = batch;
        actionReq.dynamicInputFieldNames = null;
        actionReq.dynamicInputs = dinputs;
        actionReq.triggerId = 'apex-unit-test';
        actionReq.deactivatePreviousConnections = true;
        actionReq.useFuture = false;
        actionReq.extData = extdata;

        List<RelayOnboardActionRequest> actionBatch = new List<RelayOnboardActionRequest>();
        actionBatch.add(actionReq);

        Test.startTest();   // commit our DML transaction
            List<RelayActionResponse> results = RelayOnboardingAction.onboardCustomer(actionBatch);
        Test.stopTest();

        System.assert(results != null);
    }

    static testMethod void TestOnboardingWithDynamicInputNames() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));
        List<Contact> contacts = insertTestContacts();
        List<RelayOnboardingRequest> batch = new List<RelayOnboardingRequest>();

        RelayOnboardingRequest req1 = new RelayOnboardingRequest();        
        req1.id = contacts[0].ID;
        req1.FirstName = contacts[0].FirstName;
        req1.LastName = contacts[0].LastName;
        req1.secondaryAccountId = '000-111-111';
        req1.address1 = '1 Main Street';
        req1.city = 'Media';
        req1.state_province = 'PA';
        req1.postal_code = '19063';
        req1.ccid = '1001';
        batch.add(req1);

        RelayOnboardingRequest req2 = new RelayOnboardingRequest();        
        req2.id = contacts[1].ID;
        req2.FirstName = contacts[1].FirstName;
        req2.LastName = contacts[1].LastName;
        req2.secondaryAccountId = '000-222-2222';
        req2.address1 = '1 Elm Street';
        req2.city = 'Aston';
        req2.state_province = 'PA';
        req2.postal_code = '19014';
        req2.ccid = '1002';
        batch.add(req2);
        
        RelayOnboardActionRequest actionReq = new RelayOnboardActionRequest();
        actionReq.batchRequest = batch;
        List<String> dynamicInputNames = new List<String>();
        dynamicInputNames.add('Title');
        actionReq.dynamicInputFieldNames = dynamicInputNames;
        actionReq.dynamicInputs = null;
        actionReq.triggerId = 'apex-unit-test';
        actionReq.deactivatePreviousConnections = true;
        actionReq.useFuture = false;
        actionReq.extData = null;

        List<RelayOnboardActionRequest> actionBatch = new List<RelayOnboardActionRequest>();
        actionBatch.add(actionReq);

        Test.startTest();
            List<RelayActionResponse> results = RelayOnboardingAction.onboardCustomer(actionBatch);
        Test.stopTest();

        System.assert(results != null);
    }
    
    static testMethod void TestOnboardingWithFuture() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));

        List<Contact> contacts = insertTestContacts();
        Contact contact = contacts[1];

        List<RelayOnboardingRequest> batch = new List<RelayOnboardingRequest>();

        RelayOnboardingRequest req = new RelayOnboardingRequest();
        req.id = contact.ID;
        req.FirstName = contact.FirstName;
        req.LastName = contact.LastName;
        req.ccid = '1002';
        batch.add(req);

        List<String> dynamicInputNames = new List<String>();
        dynamicInputNames.add('ReportsTo.FirstName');

        RelayOnboardActionRequest actionReq = new RelayOnboardActionRequest();
        actionReq.batchRequest = batch;
        actionReq.dynamicInputFieldNames = dynamicInputNames;
        actionReq.triggerId = 'apex-unit-test';
        actionReq.deactivatePreviousConnections = true;
        actionReq.useFuture = true;

        List<RelayOnboardActionRequest> actionBatch = new List<RelayOnboardActionRequest>();
        actionBatch.add(actionReq);

        Test.startTest();   // commit our DML transaction
            List<RelayActionResponse> results = RelayOnboardingAction.onboardCustomer(actionBatch);
        Test.stopTest();

        System.assert(results != null);
    }

    static testMethod void TestSingleOnboarding() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));

        List<Contact> contacts = insertTestContacts();
        Contact contact = contacts[1];
        System.debug(contact);

        RelayOnboardingRequest req = new RelayOnboardingRequest();
        req.id = contact.ID;
        req.FirstName = contact.FirstName;
        req.LastName = contact.LastName;
        req.ccid = '1001';

        List<String> dynamicInputNames = new List<String>();
        dynamicInputNames.add('ReportsTo.FirstName');

        RelayOnboardActionRequest actionReq = new RelayOnboardActionRequest();
        actionReq.singleRequest = req;
        actionReq.dynamicInputFieldNames = dynamicInputNames;
        actionReq.triggerId = 'apex-unit-test';
        actionReq.deactivatePreviousConnections = true;
        actionReq.useFuture = true;

        List<RelayOnboardActionRequest> actionBatch = new List<RelayOnboardActionRequest>();
        actionBatch.add(actionReq);

        Test.startTest();
            List<RelayActionResponse> results = RelayOnboardingAction.onboardCustomer(actionBatch);
        Test.stopTest();

        System.assert(results != null);
    }

    static testMethod void TestEmptyOnboarding() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));
        
        RelayOnboardActionRequest actionReq = new RelayOnboardActionRequest();
        actionReq.singleRequest = null;        
        actionReq.triggerId = 'apex-unit-test';
        actionReq.deactivatePreviousConnections = true;
        actionReq.useFuture = true;

        List<RelayOnboardActionRequest> actionBatch = new List<RelayOnboardActionRequest>();
        actionBatch.add(actionReq);

        Test.startTest();
            List<RelayActionResponse> results = RelayOnboardingAction.onboardCustomer(actionBatch);
        Test.stopTest();

        System.assert(results != null);
        RelayActionResponse rar = results[0];
        System.assertEquals(rar.responseCode, 500);
        System.assertEquals(rar.responseMessage, 'Missing batch or single onboard request');
    }
}