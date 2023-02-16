/**
 * Test for PJN_NetworkCallout
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkCalloutTest {

    static {
        PJN_TestFactoryGlobalSetting.setMock();

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
        PJN_NetworkCallout.noRunInTest = false;
    }

    @isTest
    static void testInactiveUserCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.InactiveServiceMock());

        PJN_NetworkResponse networkResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        networkResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, networkResponse, 'No Network Response found.');
        Boolean hasError = networkResponse.errors != null && !networkResponse.errors.isEmpty();
        System.assert(hasError, 'No Network Errors found.');
        System.assertEquals('User is inactive or not found.', networkResponse.errors[0].message, 'Error no found.');
    }

    @isTest
    static void testUserLockedOutCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.UserLockedOutMock());

        PJN_NetworkResponse networkResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        networkResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, networkResponse, 'No Network Response found.');
        Boolean hasError = networkResponse.errors != null && !networkResponse.errors.isEmpty();
        System.assert(hasError, 'No Network Errors found.');
        System.assertEquals('User is locked out.', networkResponse.errors[0].message, 'Error no found.');
    }

    @isTest
    static void testInvalidSessionCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.InvalidSessionMock());

        PJN_NetworkResponse networkResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        networkResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, networkResponse, 'No Network Response found.');
        Boolean hasError = networkResponse.errors != null && !networkResponse.errors.isEmpty();
        System.assert(hasError, 'No Network Errors found.');
        System.assertEquals('Invalid session ID.', networkResponse.errors[0].message, 'Error no found.');
    }

    @isTest
    static void testInsufficientAccessCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.InsufficientAccessMock());

        PJN_NetworkResponse networkResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        networkResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, networkResponse, 'No Network Response found.');
        Boolean hasError = networkResponse.errors != null && !networkResponse.errors.isEmpty();
        System.assert(hasError, 'No Network Errors found.');
        System.assertEquals('Insufficient access.', networkResponse.errors[0].message, 'Error no found.');
    }

    @isTest
    static void testOtherCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.OtherMock());

        PJN_NetworkResponse networkResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        networkResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, networkResponse, 'No Network Response found.');
        Boolean hasError = networkResponse.errors != null && !networkResponse.errors.isEmpty();
        System.assert(hasError, 'No Network Errors found.');
        System.assertEquals('Other error.', networkResponse.errors[0].message, 'Error no found.');
    }

    @isTest
    static void testSuccessCallout() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkCalloutMock.SuccessMock());
        PJN_NetworkResponse deserializeResponse;

        Test.startTest();
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/test', 'GET', null);
        deserializeResponse = networkCallout.callVeevaNetwork(null);
        Test.stopTest();

        System.assertNotEquals(null, deserializeResponse, 'Network response cannot be null.');
        System.assertEquals(PJN_NetworkConstants.NETWORK_SUCCESS, deserializeResponse.responseStatus, 'Network callout must be successful.');
    }
}