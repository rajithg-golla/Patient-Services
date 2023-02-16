/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description class to kick off several care plan problem actions
 */
public without sharing class PJN_CarePlanPathProblemActionsCtrl {
    /**
     * program problem query
     */
    @testVisible private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();

    /**
     * get program problem
     * @param   String        programProblemDeveloperName
     * @returns  Boolean
     */
    @auraEnabled public static PJN_Program_Problem__mdt getProgramProblem(String programProblemDeveloperName) {
        try {
            return programProblemQuery.queryByDeveloperName(programProblemDeveloperName);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * start care plan problem
     * @param   HealthCloudGA__CarePlanProblem__c        carePlanProblem
     * @returns  Boolean
     */
    @auraEnabled public static Boolean startCarePlanProblem(HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        try {
            PJN_CarePlanWrapper carePlan = new PJN_CarePlanWrapper(carePlanProblem.HealthCloudGA__CarePlan__c);
            carePlan.startProblem(carePlanProblem.Id, true);
            return true;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * skip care plan problem
     * @param   HealthCloudGA__CarePlanProblem__c        carePlanProblem
     * @returns  Boolean
     */
    @auraEnabled public static Boolean skipCarePlanProblem(HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        try {
            PJN_CarePlanWrapper carePlan = new PJN_CarePlanWrapper(carePlanProblem.HealthCloudGA__CarePlan__c);
            carePlan.skipProblem(carePlanProblem.Id, true);
            return true;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * delete care plan problem
     * @param   HealthCloudGA__CarePlanProblem__c        carePlanProblem
     * @returns  Boolean
     */
    @auraEnabled public static Boolean deleteCarePlanProblem(HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        try {
            return Database.delete(carePlanProblem).isSuccess();
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}