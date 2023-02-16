/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get care plan problem cases
 */
public with sharing class PJN_CarePlanProblemCasesCtrl {
    /**
     * program case query
     */
    @testVisible private static PJN_ProgramCaseQuery programCaseQuery = new PJN_ProgramCaseQuery();

    /**
     * care plan timeline case field query
     */
    @testVisible private static PJN_CarePlanTimelineCaseFieldQuery carePlanTimelineCaseFieldQuery = new PJN_CarePlanTimelineCaseFieldQuery();

    /**
     * get care plan problem cases for this problem
     * @param   HealthCloudGA__CarePlanProblem__c        carePlanProblem
     * @returns  List<PJN_CarePlanCaseWrapper>
     */
    @auraEnabled public static List<PJN_CarePlanCaseWrapper> getCarePlanProblemCases(HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        List<PJN_CarePlanCaseWrapper> carePlanCases = new List<PJN_CarePlanCaseWrapper>();
        Set<String> carePlanCaseSet = new Set<String>();
        PJN_CarePlanCaseQuery.fields.addAll(addTimelineCaseFields(carePlanProblem.HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c));
        for(Case thisCase : PJN_CarePlanCaseQuery.queryCasesByProblem(carePlanProblem.Id)) {
            if(String.isBlank(thisCase.PJN_Program_Case_DeveloperName__c)) {
                carePlanCases.add(new PJN_CarePlanCaseWrapper(thisCase));
            } else {
                carePlanCaseSet.add(thisCase.PJN_Program_Case_DeveloperName__c);
                carePlanCases.add(new PJN_CarePlanCaseWrapper(thisCase));
            }
        }
        for(PJN_Program_Case__mdt thisProgramCase : programCaseQuery.queryByProgramProblemDeveloperName(carePlanProblem.PJN_Program_Problem_DeveloperName__c)) {
            if(!carePlanCaseSet.contains(thisProgramCase.DeveloperName)) {
                carePlanCaseSet.add(thisProgramCase.DeveloperName);
                carePlanCases.add(new PJN_CarePlanCaseWrapper(thisProgramCase));
            }
        }
        return carePlanCases;
    }

    /**
     * get care plan cases by care plan program
     * @param   Id        carePlanId
     * @returns  List<PJN_CarePlanCaseWrapper>
     */
    @auraEnabled public static List<PJN_CarePlanCaseWrapper> getCarePlanCases(Id carePlanId) {
        List<PJN_CarePlanCaseWrapper> carePlanCases = new List<PJN_CarePlanCaseWrapper>();
        Case carePlan = PJN_CarePlanQuery.queryById(carePlanId);
        PJN_CarePlanCaseQuery.fields.addAll(addTimelineCaseFields(carePlan.PJN_Program_DeveloperName__c));
        for(Case thisCase : PJN_CarePlanCaseQuery.queryCasesByCarePlan(carePlanId)) {
            carePlanCases.add(new PJN_CarePlanCaseWrapper(thisCase));
        }
        return carePlanCases;
    }

    /**
     * add fields to query for for the timeline feed config
     * @param   String        programDeveloperName
     * @returns  Set<String>
     */
    private static Set<String> addTimelineCaseFields(String programDeveloperName) {
        Set<String> fields = new Set<String> { 'PJN_Activity_Timeline_Status__c' };
        for(PJN_Care_Plan_Timeline_Case_Field__mdt thisTimelineCaseField : carePlanTimelineCaseFieldQuery.queryByCarePlanProgram(programDeveloperName)) {
            fields.add(thisTimelineCaseField.PJN_Field_API_Name__c);
        }
        return fields;
    }

    /**
     * Get record type id by developer name
     * @param  developerName  record type developer name
     * @returns Id
     */
    @AuraEnabled public static Id getRecordTypeId(String developerName){
        return SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }
}