/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Wrapper class to represent cases and program cases
 */
 public with sharing class PJN_CarePlanCaseWrapper {
    /**
     * case record
     */
    @auraEnabled public Case caseRecord { get; set; }

    /**
     * program case record
     */
    @auraEnabled public PJN_Program_Case__mdt programCase { get; set; }

    /**
     * activity type: closed/open/planned
     */
    @auraEnabled public String activityType { get; set; }

    /**
     * constructor
     * @param   Case        thisCase
     */
    public PJN_CarePlanCaseWrapper(Case thisCase) {
        this.caseRecord = thisCase;
        this.activityType = thisCase.PJN_Activity_Timeline_Status__c;
    }

    /**
     * constructor
     * @param   PJN_Program_Case__mdt        thisProgramCase
     */
    public PJN_CarePlanCaseWrapper(PJN_Program_Case__mdt thisProgramCase) {
        this.programCase = thisProgramCase;
        this.activityType = 'planned';
    }
}