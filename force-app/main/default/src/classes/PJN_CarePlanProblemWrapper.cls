/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Wrapper class to represent care plan problems and the PJN_CarePlanCaseWrapper under them
 */
public with sharing class PJN_CarePlanProblemWrapper {

    /* the actual problem */
    @auraEnabled public HealthCloudGA__CarePlanProblem__c detail;

    /* list of case wrappers */
    @auraEnabled public List<PJN_CarePlanCaseWrapper> cases;

    public PJN_CarePlanProblemWrapper(HealthCloudGA__CarePlanProblem__c problem) {
        this.detail = problem;
        this.cases = new List<PJN_CarePlanCaseWrapper>();
        for (Case problemCase : problem.PJN_Cases__r) {
            cases.add(
                new PJN_CarePlanCaseWrapper(problemCase)
            );
        }
    }
}