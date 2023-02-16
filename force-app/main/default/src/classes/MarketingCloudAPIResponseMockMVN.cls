/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description Mock responses from Marketing Cloud API
 */
public class MarketingCloudAPIResponseMockMVN implements HttpCalloutMock {
    private Boolean isError;
    private List<String> subscriberKeys;
    public Boolean throwException;

    public MarketingCloudAPIResponseMockMVN(List<String> subscriberKeys) {
        this.subscriberKeys = subscriberKeys;
        this.isError = false;
        this.throwException = false;
    }

    public MarketingCloudAPIResponseMockMVN(List<String> subscriberKeys, Boolean isError) {
        this.subscriberKeys = subscriberKeys;
        this.isError = isError;
        this.throwException = false;
    }

    public MarketingCloudAPIResponseMockMVN(List<String> subscriberKeys, Boolean isError, Boolean throwException) {
        this.subscriberKeys = subscriberKeys;
        this.isError = isError;
        this.throwException = throwException;
    }

    public HttpResponse respond(HttpRequest request) {
        String endpoint = request.getEndpoint();
        HttpResponse response;

        if(throwException) {
            throw new MockException();
        } else if (endpoint.equals('callout:Marketing_Cloud_API_Authorization_MVN/v2/token')) {
            response = buildTokenRequestResponse();
        } else {
            if (!isError) {
                response = buildUpdateSubscriberResponse();
            } else {
                response = buildErrorResponse();
            }
        }

        return response;
    }

    private HTTPResponse buildTokenRequestResponse() {
        String responseBody = '{"access_token":"12345","token_type":"Bearer","expires_in":1079,"scope":"offline email_read email_send email_write sms_read sms_send sms_write list_and_subscribers_read list_and_subscribers_write data_extensions_read data_extensions_write accounts_read accounts_write users_read users_write event_notification_subscription_create event_notification_subscription_read event_notification_subscription_update event_notification_subscription_delete","soap_instance_url":"https://mc5hhvv7vg580qkdrxn1xgk16554.soap.marketingcloudapis.com/","rest_instance_url":"https://mc5hhvv7vg580qkdrxn1xgk16554.rest.marketingcloudapis.com/"}';
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody(responseBody);
        return response;
    }

    /**
     * Obtain a successful response.
     * @param  responseBody Response content to include with the response.
     * @return HTTP 200 response including the body content provided.
     */
    private HTTPResponse buildUpdateSubscriberResponse() {
        String subscriberResponse = '';
        for (Integer i = 0; i < subscriberKeys.size(); i++) {
            subscriberResponse += '<Results>';
            subscriberResponse += '<StatusCode>OK</StatusCode><StatusMessage>Updated Subscriber.</StatusMessage>';
            subscriberResponse += '<OrdinalID>' + String.valueOf(i) + '</OrdinalID>';
            subscriberResponse += '<Object xsi:type="Subscriber"><PartnerKey xsi:nil="true" /><ID>' + String.valueOf(i) + '</ID>';
            subscriberResponse += '<ObjectID xsi:nil="true" /><SubscriberKey>' + subscriberKeys[i] + '</SubscriberKey><Status>Active</Status></Object>';
            subscriberResponse += '</Results>';
        }
        String responseBody = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><soap:Header><wsa:Action>UpdateResponse</wsa:Action><wsa:MessageID>urn:uuid:bdcac8d7-8985-4101-8112-72d705a3421f</wsa:MessageID><wsa:RelatesTo>urn:uuid:7527fe77-179a-4b1c-9987-46c0b469b383</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-21bb2630-b207-4466-8fcf-d51edb518526"><wsu:Created>2020-07-21T22:57:29Z</wsu:Created><wsu:Expires>2020-07-21T23:02:29Z</wsu:Expires></wsu:Timestamp></wsse:Security></soap:Header><soap:Body><UpdateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI">' + subscriberResponse + '<RequestID>44347588-5106-4d72-adc1-7d373a7bc406</RequestID><OverallStatus>OK</OverallStatus></UpdateResponse></soap:Body></soap:Envelope>';
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'text/xml; charset=utf-8');
        response.setStatusCode(200);
        response.setBody(responseBody);
        return response;
    }

    private HTTPResponse buildErrorResponse() {
        String subscriberResponse = '';
        // subscriberResponse += '<Results>';
        subscriberResponse += '<StatusCode>ERROR</StatusCode><StatusMessage>ERROR</StatusMessage>';
        subscriberResponse += '<StatusMessage>ERROR</<StatusMessage>';
        subscriberResponse += '<ErrorCode>ERROR</ErrorCode>';
        subscriberResponse += '<Message>ERROR</Message>';
        subscriberResponse += '<faultstring>ERROR</faultstring>';
        // subscriberResponse += '</Results>';

        String responseBody = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><soap:Header><wsa:Action>UpdateResponse</wsa:Action><wsa:MessageID>urn:uuid:bdcac8d7-8985-4101-8112-72d705a3421f</wsa:MessageID><wsa:RelatesTo>urn:uuid:7527fe77-179a-4b1c-9987-46c0b469b383</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-21bb2630-b207-4466-8fcf-d51edb518526"><wsu:Created>2020-07-21T22:57:29Z</wsu:Created><wsu:Expires>2020-07-21T23:02:29Z</wsu:Expires></wsu:Timestamp></wsse:Security></soap:Header><soap:Body><UpdateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI">' + subscriberResponse + '<RequestID>44347588-5106-4d72-adc1-7d373a7bc406</RequestID><OverallStatus>ERROR</OverallStatus></UpdateResponse></soap:Body></soap:Envelope>';
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'text/xml; charset=utf-8');
        response.setStatusCode(200);
        response.setBody(responseBody);
        return response;
    }

    public class MockException extends Exception {}
}