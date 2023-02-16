/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_PAPEligibilityRequest
 * @group       AssistanceProgramEligibilty
 */
@isTest
public with sharing class PJN_PAPEligibilityRequestTest {
    private static string requestId = 'thePapRecordId';
    private static String firstName = 'John';
    private static String lastName = 'Doe';
    private static String address = '185 N. Franklin St.';
    private static String city = 'Chicago';
    private static String state ='IL';
    private static String zip = '60606-0000';
    private static String phone = '+1 (555) 555-5555';
    private static Date dateOfBirth = Date.newInstance(1982, 1, 1);
    private static String socialSecurityNumber = '000-00-0000';

    @isTest
    private static void itShouldAcceptAllParameters() {

        Test.startTest();
        PJN_PAPEligibilityRequest request = populateRequest(new PJN_PAPEligibilityRequest());
        Test.stopTest();

        System.assertEquals(requestId, request.requestId);
        System.assertEquals(firstName, request.firstName);
        System.assertEquals(lastName, request.LastName);
        System.assertEquals(address, request.address);
        System.assertEquals(city, request.city);
        System.assertEquals(state, request.state);
        System.assertEquals(zip, request.zip);
        System.assertEquals('5555555555', request.phone);
        System.assertEquals('000000000', request.socialSecurityNumber);
        System.assertEquals(dateOfBirth, request.dateOfBirth);
    }

    @isTest
    private static void itShouldValidateMissingParameters() {
        PJN_ExperianHealthApiInquiry.PJN_ExperianHealthApiInquiryException caught;
        PJN_PAPEligibilityRequest emptyRequest = new PJN_PAPEligibilityRequest();
        Test.startTest();
        System.assert(emptyRequest.isParameterMissing('requestId'));
        System.assert(emptyRequest.isParameterMissing('firstName'));
        System.assert(emptyRequest.isParameterMissing('middleName'));
        System.assert(emptyRequest.isParameterMissing('lastName'));
        System.assert(emptyRequest.isParameterMissing('phone'));
        System.assert(emptyRequest.isParameterMissing('socialSecurityNumber'));
        System.assert(emptyRequest.isParameterMissing('dateOfBirth'));
        System.assert(emptyRequest.isParameterMissing('address'));
        System.assert(emptyRequest.isParameterMissing('city'));
        System.assert(emptyRequest.isParameterMissing('state'));
        System.assert(emptyRequest.isParameterMissing('zip'));
        System.assert(emptyRequest.isParameterMissing('unknownKey'));
        Test.stopTest();
    }

    @isTest
    private static void itShouldValidateCertainInputs() {
        PJN_ExperianHealthApiInquiry.PJN_ExperianHealthApiInquiryException caught;
        PJN_PAPEligibilityRequest request = new PJN_PAPEligibilityRequest();

        PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException phoneException;
        PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException socialSecurityException;
        PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException stateException;
        Test.startTest();
        try {
            request.phone = '555';
        } catch (PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException ex) {
            phoneException = ex;
        }

        try {
            request.socialSecurityNumber = '666';
        } catch (PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException ex) {
            socialSecurityException = ex;
        }

        try {
            request.state = 'Illinois';
        } catch (PJN_PAPEligibilityRequest.PJN_PAPEligibilityRequestException ex) {
            stateException = ex;
        }
        Test.stopTest();

        System.assertEquals(Label.PJN_Eval_PAP_Invalid_Phone, phoneException.getMessage());
        System.assertEquals(Label.PJN_Eval_PAP_Invalid_SSN, socialSecurityException.getMessage());
        System.assertEquals(Label.PJN_Eval_PAP_Invalid_State, stateException.getMessage());
    }

    private static PJN_PAPEligibilityRequest populateRequest(PJN_PAPEligibilityRequest request) {
        request.requestId = requestId;
        request.firstName = firstName;
        request.LastName = lastName;
        request.address = address;
        request.city = city;
        request.state = state;
        request.zip = zip;
        request.phone = phone;
        request.socialSecurityNumber = socialSecurityNumber;
        request.dateOfBirth = dateOfBirth;

        return request;
    }
}