/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_PAPEligibilityResponse
 * @group       AssistanceProgramEligibilty
 */
@isTest
public class PJN_PAPEligibilityResponseTest {

    @isTest
    private static void itShouldPopulateTheValidResponse() {
        Test.startTest();
        PJN_PAPEligibilityResponse response = new PJN_PAPEligibilityResponse();
        response
            .setEstimatedHouseholdSize(4)
            .setEstimatedHouseholdIncome(15000)
            .setFederalPovertyLevelPercent(75.43);
        Test.stopTest();

        System.assertEquals(4, response.estimatedHouseholdSize);
        System.assertEquals(15000, response.estimatedHouseholdIncome);
        System.assertEquals(75.43, response.federalPovertyLevelPercent);
    }

    @isTest
    private static void itShouldPopulateTheInvalidResponse() {
        Test.startTest();
        PJN_PAPEligibilityResponse response = new PJN_PAPEligibilityResponse();
        response.addError('Error message');
        response.addError('Another error message');
        Test.stopTest();

        System.assertEquals(2, response.errors.size());
        System.assertEquals('Error message', response.errors[0].message);
        System.assertEquals('Another error message', response.errors[1].message);

    }
}