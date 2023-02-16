/**
 * @author      Mavens
 * @date        10/2020
 * @description Mocks an Experian Response
 * @group       ExperianHealthAPI
 */
@isTest
public class PJN_ExperianHealthAPIMock {

    public class Search implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                    '"detail": {' +
                        '"searchId": "searchId",' +
                        '"type": "searchType",' +
                        '"userName": "userName",' +
                        '"inquiry": {"fname": "fname","lname": "lname","addr": "addr","city": "city","state": "state","zip": "zip","dob": "dob","ssn": "ssn"},' +
                        '"clientInfo": {},' +
                        '"result": [' +
                            '{' +
                                '"fname": "James",' +
                                '"lname": "Dean",' +
                                '"addr": "185 N. Franklin St.",' +
                                '"city": "Chicago",' +
                                '"state": "IL",' +
                                '"zip": "60606","dob": "12/31/2007",' +
                                '"ssn": "123456789","suggestionsText": "Result address has been CASS corrected and meets USPS requirements for certified mailings.",' +
                                '"householdSizeEstimate": "4",' +
                                '"householdIncomeEstimate": "20000",' +
                                '"fplPercentage": "76.33",' +
                                '"aka.0.fname": "aka0FirstName",' +
                                '"aka.0.lname": "aka0LastName",' +
                                '"aka.0.mname": "aka0MilddleName",' +
                                '"aka.1.fname": "aka1FirstName",' +
                                '"aka.1.lname": "aka1LastName",' +
                                '"aka.1.mname": "aka1MilddleName",' +
                                '"spouse.0.fname": "spouse0FirstName",' +
                                '"spouse.0.lname": "spouse0LastName",' +
                                '"spouse.0.mname": "spouse0MilddleName",' +
                                '"spouse.0.ssn": "000000000",' +
                                '"spouse.1.fname": "spouse1FirstName",' +
                                '"spouse.1.lname": "spouse1LastName",' +
                                '"spouse.1.mname": "spouse1MilddleName",' +
                                '"spouse.1.ssn": "111111111",' +
                                '"suggestions.0.message": "suggestions0Message",' +
                                '"suggestions.1.message": "suggestions1Message"' +
                            '},' +
                            '{' +
                                '"fname": "Jimmy",' +
                                '"lname": "Dean",' +
                                '"addr": "186 N. Franklin St.",' +
                                '"city": "Chicago",' +
                                '"state": "IL",' +
                                '"zip": "60606",' +
                                '"dob": "1908",' +
                                '"dod": "12/2008",' +
                                '"ssn": "987654321"' +
                            '}' +
                        '],' +
                        '"exception": null' +
                    '}' +
                '}'
            );
            res.setStatusCode(200);
            return res;
        }
    }


    public class SearchWithError implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // set body to error
            res.setBody(
                '{' +
                    '"errors": [' +
                        '{'+
                            '"statusCode": 403,' +
                            '"code": 403, '+
                            '"exceptionMessage": "First Name is missing or has an invalid value",' +
                            '"exceptionType": "SearchException",' +
                            '"messageId": "MD22A7VPGK0"' +
                        '}' +
                    ']' +
                '}'
            );
            res.setStatusCode(403);
            return res;
        }
    }


}