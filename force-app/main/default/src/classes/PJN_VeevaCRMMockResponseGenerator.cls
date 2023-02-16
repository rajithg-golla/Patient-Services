/**
 * Mock responses for CRM Connection process.
 * @author Mavens
 */
global class PJN_VeevaCRMMockResponseGenerator implements HttpCalloutMock { //NOPMD - just global for mock

    private String caseId;
    private String eventId;
    private Boolean error;
    private String callType;

    /**
     * Overloaded constructor.
     * @param callType
     * @param caseId
     * @param eventId
     */
    public PJN_VeevaCRMMockResponseGenerator(String callType, Id caseId, Boolean error) {
        this.callType = callType;
        this.caseId = caseId;
        this.error = error;
    }

    /**
     * Overloaded constructor.
     * @param callType
     * @param eventId
     */
    public PJN_VeevaCRMMockResponseGenerator(String callType, Boolean error) {
        this.callType = callType;
        this.error = error;
    }

    /**
     * Implement this interface method.
     * @param req
     * @returns `HTTPResponse`
     */
    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        switch on req.getMethod() {
            when 'POST' {
                // in the scenario where a case id wasn't set, let's set it.
                System.debug('caseId: ' + caseId);
                System.debug('callType: ' + callType);
                if (caseId == NULL && callType == 'Suggestion') {
                    deserializeBodyAndSetCaseId(req.getBody());
                }

                if (error) {
                    res.setBody('{"hasErrors":true,"results":[{"referenceId":"' + caseId + '","errors":[{"statusCode":"ERROR","message":"Test error.","fields":[]}]}]}');
                } else {
                    res.setBody('{"hasErrors":false,"results":[{"referenceId":"' + caseId + '","id":"a4V0r000000CkgsEAC"}]}');
                }
            } when 'GET' {
                if (callType == 'Suggestion') {
                    res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v49.0/sobjects/Account/0010r00000UooLWAAZ"},"Id":"0010r00000UooLWAAZ","NPI_vod__c":"test1234"}]}');
                } else if (callType == 'CrmToSuggestion') {
                    res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Suggestion_vod__c","url":"/services/data/v49.0/sobjects/Suggestion_vod__c/0010r00000UooLWAAZ"},"Id":"' + caseId + '","Dismissed_vod__c":1,"Marked_As_Complete_vod__c":1}]}');
                }
            }
        }

        return res;
    }

    private void deserializeBodyAndSetCaseId(String body) {
        body = body.replace('__c"', '_c"').replace('__r"', '_r"');
        Object requestBody = (Object) JSON.deserializeUntyped(body);
        System.debug('requestBody: ' + requestBody);
        Map<String, Object> requestBodyMap = (Map<String, Object>) requestBody;
        System.debug('requestBodyMap: ' + requestBodyMap);
        List<Object> records = (List<Object>) requestBodyMap.get('records');
        System.debug('records: ' + records);
        String jsonRecords = JSON.serialize(records);
        List<PJN_VeevaCRMSuggestion> suggestions = (List<PJN_VeevaCRMSuggestion>) JSON.deserialize(jsonRecords, List<PJN_VeevaCRMSuggestion>.class);
        System.debug('suggestions: ' + suggestions);
        caseId = suggestions[0].attributes.referenceId;
    }
}