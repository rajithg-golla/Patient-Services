/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description used by aura component to add a problem to the patient journey
 */
public with sharing class PJN_CarePlanPathAddProblemCtrl {
    /**
     * program problem query
     */
    @testVisible private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();

    /**
     * care plan problem handler
     */
    @testVisible private static PJN_CarePlanProblemHdlr carePlanProblemHdlr = new PJN_CarePlanProblemHdlr();

    /**
     * get program problems that are inside the library
     * @param   String        programDeveloperName
     * @returns  List<PJN_Program_Problem__mdt>
     */
    @auraEnabled public static List<PJN_Program_Problem__mdt> getProgramProblemsInLibrary(String programDeveloperName) {
        try {
            return programProblemQuery.queryByProgramDeveloperNameAndLibrary(programDeveloperName);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * add program problem to patient journey (care plan)
     * @param   Id        carePlanId
     * @param   PJN_Program_Problem__mdt        programProblem
     * @returns  List<PJN_Program_Problem__mdt>
     */
    @auraEnabled public static HealthCloudGA__CarePlanProblem__c addProgramProblem(Id carePlanId, PJN_Program_Problem__mdt programProblem) {
        try {
            Case careplan = [SELECT Id, OwnerId FROM Case WHERE Id = :carePlanId];
            programProblem.PJN_Order__c = null; // reset PJN_Order__c for new addition
            carePlanProblemHdlr.programProblem = programProblem;
            HealthCloudGA__CarePlanProblem__c carePlanProblem = carePlanProblemHdlr.create(careplan);
            insert carePlanProblem;
            return carePlanProblem;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}