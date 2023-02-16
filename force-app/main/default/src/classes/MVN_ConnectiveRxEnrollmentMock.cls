/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Mock reponses from ConnectiveRx
 */
@IsTest
public with sharing class MVN_ConnectiveRxEnrollmentMock {

    public class ValidationErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"message":"Bad Request"}';
            return buildResponse(responseBody, 400);
        }
    }

    public class UnauthorizedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"message":"Unauthorized"}';
            return buildResponse(responseBody, 401);
        }
    }

    public class ForbiddenMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"code" : "UNAUTHORIZED_GROUP_ACCESS_FORBIDDEN"}';
            return buildResponse(responseBody, 403);
        }
    }

    public class UnprocessableEntityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"code":"PREEXISTENT_ENROLLMENT_UNPROCESSABLE_ENTITY","message" : "An enrollment in program XY already exists for Member Id AB and patient XYZ"}';
            return buildResponse(responseBody, 422);
        }
    }

    public class InternalServerErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"code":"INTERNAL_SERVER_ERROR","message" : "An error has occurred."}';
            return buildResponse(responseBody, 500);
        }
    }

    public class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = getResponseBody();
            return buildResponse(responseBody, 200);
        }
    }

    private static HTTPResponse buildResponse(String jsonBody, Integer statusCode) {
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(statusCode);
        response.setBody(jsonBody);

        return response;
    }

    private static String getResponseBody() {
        return '{' +
            '"success": true,' +
            '"requestId": "f5b70033-f304-4fa5-ba1e-11ba10899a59",' +
            '"traceId": "1-5ee92101-c02ef750851bcf78d1aa9ebd",' +
            '"updateStatus": "updated",' +
            '"result": {' +
                '"id": "07c3e2f4-d726-4e55-b860-2b4ab9243535",' +
                '"patient": {' +
                    '"id": "07c3e2f4-d726-4e55-b860-2b4ab9243535",' +
                    '"organizationMasterId": "123456789",' +
                    '"membership": {' +
                        '"program": "Xifaxan Savings Program",' +
                        '"groupNumber": "EC123456789",' +
                        '"memberId": "1234567890",' +
                        '"bin": "019158",' +
                        '"pcn": "CNRX",' +
                        '"isActivated": true,' +
                        '"issuedDate": "2019-12-10T00:00:00",' +
                        '"effectiveDate": "2019-12-10T00:00:00",' +
                        '"activatedDate": "2019-12-10T00:00:00",' +
                        '"expirationDate": "2020-12-10T00:00:00",' +
                        '"deactivatedDate": "2020-07-06T17:40:31Z",' +
                        '"programCap": 5500,' +
                        '"totalUses": 499,' +
                        '"usagePeriodValue": 0,' +
                        '"usagePeriodUnit": "days",' +
                        '"isActive": true' +
                    '},' +
                    '"careGiver": {' +
                        '"id": "07c3e2f4-d726-4e55-b860-2b4ab9243535",' +
                        '"relationship": "Caregiver"' +
                    '},' +
                    '"insurances": [' +
                        '{' +
                            '"insuranceTypeCode": "primary medical insurance",' +
                            '"payerName": "Horizon BCBS",' +
                            '"payerPlanName": "Advantage EPO Plan",' +
                            '"groupNumber": "GRP123",' +
                            '"memberId": "1000000001",' +
                            '"bin": "111111",' +
                            '"pcn": "meddaet"' +
                        '}' +
                    ']' +
                '},' +
                '"isActive": true,' +
                '"status": "accepted",' +
                '"isReenrollment": false,' +
                '"outcomes": [' +
                    '{' +
                    '"type": "patient-coverage",' +
                    '"success": false,' +
                    '"message": "MEDICARE, MEDICAID AND OTHER FED GOVT INSURED PATIENTS ARE NOT ELIGIBLE FOR THIS OFFER. CALL 844-692-4007 OR 908-747-2550, MON-FRI 8am-8pm ET TO CONFIRM AND PROVIDE ADDITIONAL COMMERCIAL COVERAGE DETAILS."' +
                    '}' +
                '],' +
                '"eligibilityStartDate": "2020-07-06T17:40:31Z",' +
                '"eligibilityEndDate": "2020-07-06T17:40:31Z",' +
                '"channel": "web",' +
                '"brand": "brand name",' +
                '"prescribingPhysician": {' +
                    '"id": "07c3e2f4-d726-4e55-b860-2b4ab9243535"' +
                '},' +
                '"referralPractice": {' +
                    '"id": "07c3e2f4-d726-4e55-b860-2b4ab9243535"' +
                '},' +
                '"associations": [' +
                    '{' +
                        '"associationType": "consent",' +
                        '"type": "hipaa-authorization",' +
                        '"signedDate": "2020-01-01T00:00:00.000"' +
                    '},' +
                    '{' +
                        '"associationType": "consent",' +
                        '"type": "phone-communication",' +
                        '"signedDate": "2020-06-17T16:34:09Z",' +
                        '"expiryDate": "2020-06-17T16:34:09Z"' +
                    '},' +
                    '{' +
                        '"associationType": "attestation",' +
                        '"type": "program-acceptance",' +
                        '"signedDate": "2020-01-01T00:00:00.000"' +
                    '},' +
                    '{' +
                        '"associationType": "attestation",' +
                        '"type": "age",' +
                        '"signedDate": "2018-07-13T15:53:00",' +
                        '"age": "18"' +
                    '}' +
                '],' +
                '"metaInfo": [' +
                    '{' +
                        '"type": "annotations",' +
                        '"key": "Specialty-Pharmacy-ID",' +
                        '"value": "CareABC",' +
                        '"displayName": "Specialty Pharmacy",' +
                        '"description": "CareABC"' +
                    '}' +
                '],' +
                '"benefitTypes": [' +
                    '"drug"' +
                ']' +
            '}' +
        '}';
    }
}