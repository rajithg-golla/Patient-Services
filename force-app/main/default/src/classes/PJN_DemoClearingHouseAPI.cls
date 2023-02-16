/**
 * @author      Mavens
 * @date        10/2020
 * @description Simple implementation of the clearing house API to get started without needing
 *              to have creds to call a financial clearing house
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_DemoClearingHouseAPI implements PJN_FinancialClearingHouseIntf{

    public static Integer income = 20000;
    public static Integer size = 4;
    public static Decimal federalPovertyLevel = 76.33;

    public PJN_PAPEligibilityResponse getEligibility(PJN_PAPEligibilityRequest request) {
        return new PJN_PAPEligibilityResponse()
            .setEstimatedHouseholdIncome(income)
            .setEstimatedHouseholdSize(size)
            .setFederalPovertyLevelPercent(federalPovertyLevel);
    }

}