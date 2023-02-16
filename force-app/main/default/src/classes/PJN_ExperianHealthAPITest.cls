/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_ExperianHealthAPI
 * @group       ExperianHealthAPI
 */
@isTest
public class PJN_ExperianHealthAPITest {

    private static PJN_PAPEligibilityRequest request;
    static {
        String firstName = 'John';
        String lastName = 'Doe';
        String address = '185 N. Franklin St.';
        String city = 'Chicago';
        String state ='IL';
        String zip = '60606-0000';
        String phone = '+1 (555) 555-5555';
        Date dateOfBirth = Date.newInstance(1982, 1, 1);
        String socialSecurityNumber = '000-00-0000';

        request = new PJN_PAPEligibilityRequest();

        request.requestId = 'thePapRecordId';
        request.firstName = firstName;
        request.LastName = lastName;
        request.address = address;
        request.city = city;
        request.state = state;
        request.zip = zip;
        request.phone = phone;
        request.socialSecurityNumber = socialSecurityNumber;
        request.dateOfBirth = dateOfBirth;
    }

    @isTest
    private static void itShouldPerformASearchCallout() {

        Test.setMock(HttpCalloutMock.class, new PJN_ExperianHealthAPIMock.Search());
        Test.startTest();
        PJN_PAPEligibilityResponse response = new PJN_ExperianHealthAPI().getEligibility(request);
        Test.stopTest();

        System.assertEquals(4, response.estimatedHouseholdSize);
        System.assertEquals(20000, response.estimatedHouseholdIncome);
        System.assertEquals(76.33, response.federalPovertyLevelPercent);
    }

    @isTest
    private static void itShouldValidateMissingParameters() {
        PJN_ExperianHealthApiInquiry.PJN_ExperianHealthApiInquiryException caught;
        PJN_PAPEligibilityRequest emptyRequest = new PJN_PAPEligibilityRequest();
        Test.startTest();
        try {
            new PJN_ExperianHealthAPI().getEligibility(emptyRequest);
        } catch (PJN_ExperianHealthApiInquiry.PJN_ExperianHealthApiInquiryException ex) {
            caught = ex;
        }
        Test.stopTest();

        System.assertEquals(
            'Required parameters missing: Request Id, First Name, Last Name, Address, City, State, Zip.',
            caught.getMessage()
        );
    }

    @isTest
    private static void itShouldHandleAnErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new PJN_ExperianHealthAPIMock.SearchWithError());

        Test.startTest();
        PJN_PAPEligibilityResponse response = new PJN_ExperianHealthAPI().getEligibility(request);
        Test.stopTest();

        System.assert(response.hasErrors);
        System.assertEquals(
            'First Name is missing or has an invalid value (Message Id: MD22A7VPGK0)',
            response.errors[0].message
        );
    }
}