/**
 * @author      Mavens
 * @date        10/2020
 * @description Interface to implment to use the Financial Clearing House functionality
 * @group       AssistanceProgramEligibilty
 */
public interface PJN_FinancialClearingHouseIntf {
    PJN_PAPEligibilityResponse getEligibility(PJN_PAPEligibilityRequest request);
}