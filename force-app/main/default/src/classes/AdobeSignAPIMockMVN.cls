global class AdobeSignAPIMockMVN implements HttpCalloutMock {
   
    global HTTPResponse respond(HTTPRequest req) {
        if (req.getEndpoint() == Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().Authentication_Endpoint_MVN__c + 'oauth/refresh') {
            return handleAccessToken(req);
        } else if (req.getEndpoint() == Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().REST_API_Endpoint_MVN__c + 'agreements') {
            return handleSendForSigning(req);
        } else if (req.getEndpoint() == Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().REST_API_Endpoint_MVN__c + 'webhooks') {
            return handleWebhooks(req);
        } else if (req.getEndpoint().endsWith('/combinedDocument')) {
            return handleCombinedDocument(req);
        } else if (req.getEndpoint().endsWith('/formData')) {
            return handleFormData(req);
        } else if (req.getEndpoint().endsWith('/signingUrls')) {
            return handleSigningUrls(req);
        }

        return null;
    }

    private HTTPResponse handleAccessToken(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());
        System.assertEquals('application/x-www-form-urlencoded', req.getHeader('Content-Type'));

        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(200);
        response.setBody(
            '{ "access_token":"1234567890Access"}'
        );

        return response;
    }

    private HttpResponse handleSendForSigning(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());
        System.assertEquals('application/json', req.getHeader('Content-Type'));

        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(201);
        response.setBody(
            '{ "id":"1234567890Id"}'
        );

        return response;
    }

    private HttpResponse handleWebhooks(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());
        System.assertEquals('application/json', req.getHeader('Content-Type'));
        
        Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(req.getBody());
        System.assertEquals('Notify Salesforce of Agreement Updates', (String)body.get('name'));
        System.assertEquals('USER', (String)body.get('scope'));
        System.assertEquals('ACTIVE', (String)body.get('state'));
        System.assertEquals('AGREEMENT_ACTION_COMPLETED',(String) ((List<Object>)body.get('webhookSubscriptionEvents'))[0]);
        System.assertEquals(
            Regeneron_Adobe_Sign_Settings_MVN__c.getOrgDefaults().Webhook_Public_Site_MVN__c, 
            (String)((Map<String,Object>)body.get('webhookUrlInfo')).get('url')
        );

        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(201);
        response.setBody(
            '{ "id":"1234567890WebhookId"}'
        );

        return response;
    }

    private HttpResponse handleCombinedDocument(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        System.assertEquals('Bearer 1234567890Access', req.getHeader('Authorization'));

        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(200);
        response.setBody( 'APDFStringAsABlob' );

        return response;
    }   

    private HttpResponse handleFormData(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        System.assertEquals('Bearer 1234567890Access', req.getHeader('Authorization'));

        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(200);
        response.setBody( '"first","last\n"DeanUpdated","Martin"');

        return response;
    }

    private HttpResponse handleSigningUrls(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        System.assertEquals('Bearer 1234567890Access', req.getHeader('Authorization'));
        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(200);

        AdobeSignAPIMVN.SigningUrl url = new AdobeSignAPIMVN.SigningUrl();
        url.esignUrl = 'https://signingurl.adobesign.com';

        AdobeSignAPIMVN.SigningUrlSetInfo urlSet = new AdobeSignAPIMVN.SigningUrlSetInfo();
        urlSet.signingUrls = new List<AdobeSignAPIMVN.SigningUrl> { url };

        AdobeSignAPIMVN.SigningUrlResponse urlResponse = new AdobeSignAPIMVN.SigningUrlResponse();
        urlResponse.signingUrlSetInfos = new List<AdobeSignAPIMVN.SigningUrlSetInfo>{ urlSet };

        response.setBody(JSON.serialize(urlResponse));

        return response;
    }
}