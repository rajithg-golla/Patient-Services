/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description Unit tests for MarketingCloudSoapAPIMVN
 */
@isTest
private class MarketingCloudSoapAPITestMVN {

    @isTest
    static void itShouldUpdateSubscriberStatusWithTwoParams() {
        String subscriberKey = 'Test';
        String status = 'Active';
        MarketingCloudAPIResponseMockMVN mock = new MarketingCloudAPIResponseMockMVN(new List<String> { subscriberKey });
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MarketingCloudSoapAPIMVN api = new MarketingCloudSoapAPIMVN();
        String result = api.updateSubscriberStatus(subscriberKey, status);
        Test.stopTest();
        System.assert(result.contains('Successfully updated Subscriber'));
    }

    @isTest
    static void itShouldUpdateSubscriberStatusWithThreeParams() {
        String subscriberKey = 'Test';
        String status = 'Active';
        String emailAddress = 'test@test.com';
        MarketingCloudAPIResponseMockMVN mock = new MarketingCloudAPIResponseMockMVN(new List<String> { subscriberKey });
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MarketingCloudSoapAPIMVN api = new MarketingCloudSoapAPIMVN();
        String result = api.updateSubscriberStatus(subscriberKey, status, emailAddress);
        Test.stopTest();
        System.assert(result.contains('Successfully updated Subscriber'));
    }

    @isTest
    static void itShouldUpdateStatusForSubscribers() {
        Map<String, Map<String, String>> statusMap = new Map<String, Map<String, String>>{
            'Test1' => new Map<String,String> {
                'SubscriberKey' => 'Test1',
                'Status' => 'Active',
                'EmailAddress' => 'test@test.com'
            },
            'Test2' => new Map<String,String> {
                'SubscriberKey' => 'Test2',
                'Status' => 'Unsubscribed',
                'EmailAddress' => 'test@test.com'
            }
        };
        MarketingCloudAPIResponseMockMVN mock = new MarketingCloudAPIResponseMockMVN(new List<String>(statusMap.keySet()));
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MarketingCloudSoapAPIMVN api = new MarketingCloudSoapAPIMVN();
        Map<String,String> result = api.updateSubscribersStatus(statusMap);
        Test.stopTest();
        System.assertEquals(2, result.size());
        System.assert(result.get('Test1').contains('Updated Subscriber'));
        System.assert(result.get('Test2').contains('Updated Subscriber'));
    }

    @isTest
    static void itShouldGetErrorMessage() {
        String subscriberKey = 'Test';
        String status = 'Active';
        String emailAddress = 'test@test.com';
        MarketingCloudAPIResponseMockMVN mock = new MarketingCloudAPIResponseMockMVN(new List<String> { subscriberKey }, true);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MarketingCloudSoapAPIMVN api = new MarketingCloudSoapAPIMVN();
        String result = api.updateSubscriberStatus(subscriberKey, status, emailAddress);
        Test.stopTest();
        System.assert(result.contains('ErrorCode:'));
    }
}