/**
 * Veeva Network responses for each callout
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkCalloutMock {

    public class InactiveServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INACTIVE_USER","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';
            return buildResponse(responseBody);
        }
    }

    public class UserLockedOutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"USER_LOCKED_OUT","message":"User is locked out."}],"errorType" : "AUTHENTICATION_FAILED"}';
            return buildResponse(responseBody);
        }
    }

    public class InvalidSessionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INVALID_SESSION_ID","message":"Invalid session ID."}],"errorType" : "AUTHENTICATION_FAILED"}';
            return buildResponse(responseBody);
        }
    }

    public class InsufficientAccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INSUFFICIENT_ACCESS","message":"Insufficient access."}],"errorType" : "AUTHENTICATION_FAILED"}';
            return buildResponse(responseBody);
        }
    }

    public class OtherMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"Other","message":"Other error."}],"errorType" : "AUTHENTICATION_FAILED"}';
            return buildResponse(responseBody);
        }
    }

    public class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            if(req.getEndpoint().contains('/auth')) {
                responseBody =
                '{"responseStatus":"SUCCESS","sessionId":"newSession12345"}';
            } else {
                responseBody =
                '{"responseStatus":"SUCCESS","message":"SUCCESS"}';
            }

            return buildResponse(responseBody);
        }
    }

    private static HTTPResponse buildResponse(String jsonBody) {
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody(jsonBody);

        return response;
    }
}