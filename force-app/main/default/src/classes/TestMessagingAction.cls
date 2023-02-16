@isTest
public class TestMessagingAction {
    static testMethod void TestMessagingActionWithoutFuture() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200 , '{}'));

        String CCID = '1001';
        Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');

        Insert newContact;

        List<RelayMessagingRequest> batch = new List<RelayMessagingRequest>();

        RelayMessagingRequest msgreq = new RelayMessagingRequest();
        msgreq.id = newContact.ID;
        msgreq.ccid = CCID;
        batch.add(msgreq);

        List<String> dynamicInputNames = new List<String>();
        dynamicInputNames.add('ReportsTo.FirstName');

        RelayMessageActionRequest req = new RelayMessageActionRequest();
        req.batchRequest = batch;
        req.dynamicInputFieldNames = dynamicInputNames;
        req.triggerId = 'apex-unit-test';
        req.useFuture = false;
        List<RelayMessageActionRequest> actionRequest = new List<RelayMessageActionRequest>();
        actionRequest.add(req);

        Test.startTest();   
            List<RelayActionResponse> results = RelayMessageAction.execute(actionRequest);
        Test.stopTest();

        System.assert(results != null);
    }

    static testMethod void TestMessagingActionWithBadId() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200 , '{}'));

        String CCID = '1001';
        Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');

        Insert newContact;

        List<RelayMessagingRequest> batch = new List<RelayMessagingRequest>();

        RelayMessagingRequest msgreq = new RelayMessagingRequest();
        msgreq.id = '0033j00003CsRMgAAN';
        msgreq.ccid = CCID;
        batch.add(msgreq);

        List<String> dynamicInputNames = new List<String>();
        dynamicInputNames.add('ReportsTo.FirstName');

        RelayMessageActionRequest req = new RelayMessageActionRequest();
        req.batchRequest = batch;
        req.dynamicInputFieldNames = dynamicInputNames;
        req.triggerId = 'apex-unit-test';
        req.useFuture = false;
        List<RelayMessageActionRequest> actionRequest = new List<RelayMessageActionRequest>();
        actionRequest.add(req);

        Test.startTest();   
            List<RelayActionResponse> results = RelayMessageAction.execute(actionRequest);
        Test.stopTest();
        
        System.debug(results);
        
        System.assert(results != null);
        System.assertEquals(200, results[0].responseCode, 'Invalid response code');
        System.assertEquals('No record found, nothing to do', results[0].responseMessage, 'Invalid response message');
        
    }

    static testMethod void TestMessagingActionWithFuture() {
        Test.setMock(HttpCalloutMock.class, new RelayHttpMock('batch messaging', 'POST', 200, '{}'));

        String CCID = '1001';
        Contact newContact = new Contact(FirstName='Test', LastName='Coverage',  MobilePhone='1005551212');
        Insert newContact;

        RelayMessagingRequest msgreq = new RelayMessagingRequest();
        msgreq.id = newContact.ID;
        msgreq.ccid = CCID;
        RelayMessageActionRequest req = new RelayMessageActionRequest();
        req.singleRequest = msgreq;
        req.useFuture = true;

        List<RelayMessageActionRequest> actionRequest = new List<RelayMessageActionRequest>();
        actionRequest.add(req);

        List<RelayActionResponse> results = RelayMessageAction.execute(actionRequest);

        System.assert(results != null);
    }

    static testMethod void testEmptyMessageActionRequest() {

        RelayMessageActionRequest req = new RelayMessageActionRequest();
        req.singleRequest = null;
        req.useFuture = false;

        List<RelayMessageActionRequest> actionRequest = new List<RelayMessageActionRequest>();
        actionRequest.add(req);

        List<RelayActionResponse> results = RelayMessageAction.execute(actionRequest);
        System.assert(results != null, 'No results were returned');
        RelayActionResponse rsp = results[0];
        System.assertEquals(500, rsp.responseCode, 'Invalid response code');
        System.assertEquals('No record ids', rsp.responseMessage, 'Invalid response message');

    }

    static testMethod void testDynamicInput() {
        RelayDynamicInput di = new RelayDynamicInput();
        di.inputName = 'dob';
        di.inputValue = '1970-01-01';

        System.assertEquals(di.inputName, 'dob');
        System.assertEquals(di.inputValue, '1970-01-01');
    }
}