@isTest
global class RelayHttpMock implements HttpCalloutMock {

    private String g_apiName;
    private String g_method;
    private Integer statusCode;
    private String jsonResponse;

    public RelayHttpMock(String apiName, String method, Integer statusCode, String jsonResponse) {
        this.g_apiName = apiName;
        this.g_method = method;
        this.statusCode = statusCode;
        this.jsonResponse = jsonResponse;
    }

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // System.assertEquals('http://example.com/example/test', req.getEndpoint());
        // System.assertEquals(this.g_method, req.getMethod());

        String body = req.getBody();
        System.debug(body);

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setBody(jsonResponse);
        
        if (this.g_apiName == 'consent-update-batch-async') {
            verifyConsentUpdateBatchAsyncBody(body);
        }

        return res;
    }

    /*
    ** Helper methods for verifying Consent update HTTP requests
    */

    private void verifyConsentUpdateBatchAsyncBody(String body) {
        ConsentBatchUpdateReq req = (ConsentBatchUpdateReq)JSON.deserialize(body, ConsentBatchUpdateReq.class);

        System.assert(req != null);
        System.assert(req.batch.size() == 10);  // set from test oin TestRelay.cls
        Boolean foundFirst = false;
        Boolean foundLast = false;
        for (ConsentUpdateBody cu : req.batch) {
            if (cu.channel_addr == '1005550000')
                foundFirst = true;
            else if (cu.channel_addr == '1005550009')
                foundLast = true;
        }        
        System.assert(foundFirst == true);
        System.assert(foundLast == true);
    }

    class ConsentBatchUpdateReq {
        public List<ConsentUpdateBody> batch;
    }
    
    class ConsentUpdateBody {
        public String channe_type;
        public String channel_addr;
        public String consent_type;
    }
}