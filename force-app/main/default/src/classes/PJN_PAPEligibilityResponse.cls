/**
 * @author      Mavens
 * @date        10/2020
 * @description Provides functionality to handle a PJN_PAPEligibility response
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_PAPEligibilityResponse {

    @AuraEnabled public Integer estimatedHouseholdSize { get; private set; }
    @AuraEnabled public Integer estimatedHouseholdIncome { get; private set; }
    @AuraEnabled public Decimal federalPovertyLevelPercent { get; private set; }
    @AuraEnabled public String outcome { get; private set; }

    @AuraEnabled public List<Error> errors { get; private set; }

    public PJN_PAPEligibilityResponse setEstimatedHouseholdSize(Integer estimatedHouseholdSize) {
        this.estimatedHouseholdSize = estimatedHouseholdSize;
        return this;
    }

    public PJN_PAPEligibilityResponse setEstimatedHouseholdIncome(Integer estimatedHouseholdIncome) {
        this.estimatedHouseholdIncome = estimatedHouseholdIncome;
        return this;
    }

    public PJN_PAPEligibilityResponse setFederalPovertyLevelPercent(Decimal federalPovertyLevelPercent) {
        this.federalPovertyLevelPercent = federalPovertyLevelPercent;
        return this;
    }

    public PJN_PAPEligibilityResponse setOutcome(String outcome) {
        this.outcome = outcome;
        return this;
    }

    public PJN_PAPEligibilityResponse() {
        this.errors = new List<Error>();
    }

    public void addError(String message) {
        this.errors.add(
            new Error(message)
        );
    }

    @AuraEnabled public Boolean hasErrors {
        get {
            return !this.errors.isEmpty();
        }
    }

    public class Error {
        @AuraEnabled public String message;

        public Error(String message) {
            this.message = message;
        }
    }
}