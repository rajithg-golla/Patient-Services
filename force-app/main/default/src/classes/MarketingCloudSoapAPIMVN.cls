/**
 * @author Mavens
 * @date Jul 16, 2020
 * @description SOAP API Client for Marketing Cloud
 */
public with sharing class MarketingCloudSoapAPIMVN {
    private static final Integer ONE_HUNDRED_TWENTY_SECONDS = 120000;

    private String authorizationToken = '';
    private String soapInstanceUrl = '';

    public MarketingCloudSoapAPIMVN() {
        TokenResponse authorizationTokenResponse = getAuthorizationToken();

        authorizationToken = authorizationTokenResponse.access_token;
        soapInstanceUrl = authorizationTokenResponse.soap_instance_url;
    }

    public TokenResponse getAuthorizationToken() {
        TokenResponse authorizationTokenResponse = null;

        TokenRequest tokenRequest = new TokenRequest();

        String tokenRequestBody = JSON.serialize(tokenRequest);

        HttpRequest httpRequest = new HttpRequest();

        httpRequest.setEndpoint('callout:Marketing_Cloud_API_Authorization_MVN/v2/token');
        httpRequest.setTimeout(ONE_HUNDRED_TWENTY_SECONDS);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type','application/json');
        httpRequest.setBody(tokenRequestBody);

        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        Integer httpResponseStatusCode = httpResponse.getStatusCode();
        String httpResponseBody = httpResponse.getBody();

        if(httpResponseStatusCode == 200) {
            authorizationTokenResponse = (TokenResponse)JSON.deserialize(httpResponseBody, TokenResponse.class);
        } else {
            System.debug('Authorization Token Request failed with status code: ' + httpResponseStatusCode + '\n\n' + httpResponseBody + '\n\nWith Request URL:\n' + httpRequest.getEndpoint() + '\n\nWith Reqest Body:\n' + tokenRequestBody);
        }

        return authorizationTokenResponse;
    }

    class TokenRequest {
        public String grant_type = 'client_credentials';
        public String client_id = '{!HTMLENCODE($Credential.Username)}';
        public String client_secret = '{!HTMLENCODE($Credential.Password)}';
    }

    class TokenResponse {
        public String access_token;
        public String soap_instance_url;
    }

    public String updateSubscriberStatus(String subscriberKey, String status) {
        String result = null;

        String updateSubscriberRequestBody = '' +
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '<s:Header>' +
                    '<fueloauth>' + this.authorizationToken + '</fueloauth>' +
            '</s:Header>' +
            '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
                '<UpdateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
                    '<Objects xsi:type="Subscriber">' +
                        '<SubscriberKey>' + subscriberKey + '</SubscriberKey>' +
                        '<Status>' + status + '</Status>' +
                    '</Objects>' +
                '</UpdateRequest>' +
            '</s:Body>' +
        '</s:Envelope>';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(soapInstanceUrl + 'Service.asmx');
        httpRequest.setTimeout(ONE_HUNDRED_TWENTY_SECONDS);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type','text/xml; charset=UTF-8');
        httpRequest.setHeader('SOAPAction','Update');
        httpRequest.setBody(updateSubscriberRequestBody);

        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        Integer httpResponseStatusCode = httpResponse.getStatusCode();
        String httpResponseBody = httpResponse.getBody();

        if(httpResponseStatusCode == 200) {
            String overallStatus = httpResponseBody.subStringBetween('<OverallStatus>', '</OverallStatus>');
            if(overallStatus == 'OK') {
                String statusMessage = httpResponseBody.subStringBetween('<StatusMessage>', '</StatusMessage>');
                result = '[' + statusMessage + '] Successfully updated Subscriber (' + subscriberKey + ')' + ' status to: ' + status;
            } else {
                result = getErrorMessage(httpResponseBody);
            }
        } else {
            throw new MarketingCloudSoapAPIMVNException('Subscriber Update Request failed with status code: ' + httpResponseStatusCode + '\n\n' + httpResponseBody + '\n\nWith Request URL:\n' + httpRequest.getEndpoint() + '\n\nWith Reqest Body:\n' + updateSubscriberRequestBody);
        }

        return result;
    }

    public String updateSubscriberStatus(String subscriberKey, String status, String emailAddress) {
        String result = null;

        String updateSubscriberRequestBody = '' +
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '<s:Header>' +
                    '<fueloauth>' + this.authorizationToken + '</fueloauth>' +
            '</s:Header>' +
            '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
                '<UpdateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
                    '<Objects xsi:type="Subscriber">' +
                        '<SubscriberKey>' + subscriberKey + '</SubscriberKey>' +
                        '<Status>' + status + '</Status>' +
                        '<EmailAddress>' + emailAddress + '</EmailAddress>' +
                    '</Objects>' +
                '</UpdateRequest>' +
            '</s:Body>' +
        '</s:Envelope>';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(soapInstanceUrl + 'Service.asmx');
        httpRequest.setTimeout(ONE_HUNDRED_TWENTY_SECONDS);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type','text/xml; charset=UTF-8');
        httpRequest.setHeader('SOAPAction','Update');
        httpRequest.setBody(updateSubscriberRequestBody);

        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        Integer httpResponseStatusCode = httpResponse.getStatusCode();
        String httpResponseBody = httpResponse.getBody();

        if(httpResponseStatusCode == 200) {
            String overallStatus = httpResponseBody.subStringBetween('<OverallStatus>', '</OverallStatus>');
            if(overallStatus == 'OK') {
                String statusMessage = httpResponseBody.subStringBetween('<StatusMessage>', '</StatusMessage>');
                result = '[' + statusMessage + '] Successfully updated Subscriber (' + subscriberKey + ')' + ' status to: ' + status;
            } else {
                result = getErrorMessage(httpResponseBody);
            }
        } else {
            throw new MarketingCloudSoapAPIMVNException('Subscriber Update Request failed with status code: ' + httpResponseStatusCode + '\n\n' + httpResponseBody + '\n\nWith Request URL:\n' + httpRequest.getEndpoint() + '\n\nWith Reqest Body:\n' + updateSubscriberRequestBody);
        }

        return result;
    }

    private String getErrorMessage(String httpResponseBody) {
        String errorMessage = '';

        errorMessage += '\nStatus Message: ' + httpResponseBody.subStringBetween('<StatusMessage>', '</StatusMessage>');
        errorMessage += '\nErrorCode: ' + httpResponseBody.subStringBetween('<ErrorCode>', '</ErrorCode>');
        errorMessage += '\nMessage: ' + httpResponseBody.subStringBetween('<Message>', '</Message>');
        errorMessage += '\nFaulString: ' + httpResponseBody.subStringBetween('<faultstring>', '</faultstring>');

        return errorMessage;
    }

    public Map<String, String> updateSubscribersStatus(Map<String, Map<String, String>> statusBySubscriberKey) {
        Map<String, String> updateSubscribersResults = new Map<String, String>();

        List<String> subscriberObjects = new List<String>();

        for(String subscriberKey : statusBySubscriberKey.keySet()) {
            Map<String, String> valueMap = statusBySubscriberKey.get(subscriberKey);
            String subscriberObject =  '<Objects xsi:type="Subscriber">';

            for (String key : valueMap.keySet()) {
                subscriberObject += '<' + key + '>' + valueMap.get(key) + '</' + key + '>';
            }

            subscriberObject += '</Objects>';

            subscriberObjects.add(subscriberObject);
        }

        String updateSubscriberRequestBody = '' +
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '<s:Header>' +
                    '<fueloauth>' + this.authorizationToken + '</fueloauth>' +
            '</s:Header>' +
            '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
                '<UpdateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
                    String.join(subscriberObjects, '') +
                '</UpdateRequest>' +
            '</s:Body>' +
        '</s:Envelope>';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(soapInstanceUrl + 'Service.asmx');
        httpRequest.setTimeout(ONE_HUNDRED_TWENTY_SECONDS);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type','text/xml; charset=UTF-8');
        httpRequest.setHeader('SOAPAction','Update');
        httpRequest.setBody(updateSubscriberRequestBody);

        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        Integer httpResponseStatusCode = httpResponse.getStatusCode();
        String httpResponseBody = httpResponse.getBody();

        if(httpResponseStatusCode == 200) {
            String updateResponse = httpResponseBody.substringBetween('<UpdateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI">', '</UpdateResponse>');
            List<String> results = updateResponse.split('<Results>');

            for(String result : results) {
                System.debug('#### result: ' + result);
                String subscriberKey = result.substringBetween('<SubscriberKey>','</SubscriberKey>');
                if(subscriberKey != null) {
                    String overallStatus = result.subStringBetween('<StatusCode>', '</StatusCode>');
                    if(overallStatus == 'OK') {
                        String statusMessage = result.subStringBetween('<StatusMessage>', '</StatusMessage>');

                        updateSubscribersResults.put(subscriberKey, statusMessage);
                    } else {
                        updateSubscribersResults.put(subscriberKey, getErrorMessage(result));
                    }
                }
            }
        } else {
            throw new MarketingCloudSoapAPIMVNException('Subscriber Update Request failed with status code: ' + httpResponseStatusCode + '\n\n' + httpResponseBody + '\n\nWith Request URL:\n' + httpRequest.getEndpoint() + '\n\nWith Reqest Body:\n' + updateSubscriberRequestBody);
        }

        System.debug('#### updateSubscribersResults: ' + updateSubscribersResults);
        return updateSubscribersResults;
    }

    public class MarketingCloudSoapAPIMVNException extends Exception {}
}