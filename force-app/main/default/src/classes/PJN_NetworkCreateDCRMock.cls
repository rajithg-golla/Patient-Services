/**
 * Network Create DCR Callout Mocks
 * @author  Mavens
 * @group   Network
 */
@IsTest
public class PJN_NetworkCreateDCRMock {

    /**
     * Error callout mock
     */
    public class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            if(req.getEndpoint().contains('/oauth2')) {
                responseBody =
                '{"sessionId":"NETWORKSESSIONID","responseStatus":"SUCCESS","responseMessage":null,"reserved_vid":null,"errors":null}';
            } else {
                System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Create Mock body: ' + req.getBody());
                // Map<String, Object> changeRequest = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
                responseBody = '{"responseStatus":"FAILURE","responseMessage":"Required fields are missing: lastname__v","errors":[{"type":"UNEXPECTED_ERROR","message":null}]}';
            }

            return buildResponse(responseBody);
        }
    }

    /**
     * Success callout mock
     */
    public class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            if(req.getEndpoint().contains('/oauth2')) {
                responseBody =
                '{"sessionId":"NETWORKSESSIONID","responseStatus":"SUCCESS","responseMessage":null,"reserved_vid":null,"errors":null}';
            } else {
                System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Create Mock body: ' + req.getBody());
                Map<String, Object> records = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
                List<Object> ccsResults = new List<Object>();

                // for (Object recordObj : (List<Object>) records.get('records')) {
                //     Map<String, Object> record = (Map<String, Object>) recordObj;
                //     Map<String, Object> attributes = (Map<String, Object>) record.get('attributes');

                //     ccsResults.add(
                //         new Map<String, Object> {
                //             'referenceId' => attributes.get('referenceId'),
                //             'errors' => new List<Object>(),
                //             'id' => attributes.get('referenceId') + 'NewCCS'
                //         }
                //     );
                // }

                responseBody = '{"hasErrors": false, "results": ' + System.JSON.serialize(ccsResults, true) + '}';
            }

            return buildResponse(responseBody);
        }
    }

    /**
     * Build HTTP Response using mock
     * @param jsonBody  HTTP Response body
     * @returns `HTTPResponse`
     */
    private static HTTPResponse buildResponse(String jsonBody) {
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody(jsonBody);

        return response;
    }
}