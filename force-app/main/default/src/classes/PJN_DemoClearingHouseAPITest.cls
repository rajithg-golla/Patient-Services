@isTest
public class PJN_DemoClearingHouseAPITest {

    @isTest
    private static void itShouldReturnDemoData() {

        Test.startTest();
        PJN_DemoClearingHouseAPI chAPI = new PJN_DemoClearingHouseAPI();
        PJN_PAPEligibilityResponse response = chAPI.getEligibility(
            new PJN_PAPEligibilityRequest(
                new PJN_Assistance_Program__c()
            )
        );
        Test.stopTest();

        System.assertEquals(20000, response.estimatedHouseholdIncome);
        System.assertEquals(4, response.estimatedHouseholdSize);
        System.assertEquals(76.33, response.federalPovertyLevelPercent);
    }

    @isTest
    private static void itShouldReturnSetDemoData() {

        PJN_DemoClearingHouseAPI.income = 100000;
        PJN_DemoClearingHouseAPI.size = 3;
        PJN_DemoClearingHouseAPI.federalPovertyLevel = 460.4;


        Test.startTest();
        PJN_DemoClearingHouseAPI chAPI = new PJN_DemoClearingHouseAPI();
        PJN_PAPEligibilityResponse response = chAPI.getEligibility(
            new PJN_PAPEligibilityRequest(
                new PJN_Assistance_Program__c()
            )
        );
        Test.stopTest();

        System.assertEquals(100000, response.estimatedHouseholdIncome);
        System.assertEquals(3, response.estimatedHouseholdSize);
        System.assertEquals(460.4, response.federalPovertyLevelPercent);
    }
}