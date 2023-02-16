/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get all care plan problems for one care plan
 */
public with sharing class PJN_CarePlanUICtrl {
    /**
     * get care plan problems for care plan id
     * @param   Id        carePlanId
     * @returns  List<HealthCloudGA__CarePlanProblem__c>
     */
	@auraEnabled public static List<HealthCloudGA__CarePlanProblem__c> getCarePlanProblems(Id carePlanId) {
        return PJN_CarePlanProblemQuery.queryByCarePlanId(carePlanId);
    }

    /**
     * program case query
     */
    @testVisible private static PJN_ProgramCaseQuery programCaseQuery = new PJN_ProgramCaseQuery();

    /**
     * care plan timeline case field query
     */
    @testVisible private static PJN_CarePlanTimelineCaseFieldQuery carePlanTimelineCaseFieldQuery = new PJN_CarePlanTimelineCaseFieldQuery();

    @auraEnabled public static List<PJN_CarePlanProblemWrapper> getWrappedCarePlanProblems(Id carePlanId, String variant) {

        PJN_CarePlanCaseQuery.fields.addAll(addTimelineCaseFields(carePlanId));
        List<HealthCloudGA__CarePlanProblem__c> carePlanProblems = PJN_CarePlanProblemQuery.queryByCarePlanId(carePlanId, variant != 'open');


        // the list to hold all the wrapped problems
        List<PJN_CarePlanProblemWrapper> wrappedProblems = new List<PJN_CarePlanProblemWrapper>();

        // track if the additional activity is available
        PJN_CarePlanProblemWrapper additionalActivity;

        for (HealthCloudGA__CarePlanProblem__c carePlanProblem : carePlanProblems) {

            PJN_CarePlanProblemWrapper currentCarePlanProblem = new PJN_CarePlanProblemWrapper(carePlanProblem);
            if (carePlanProblem.PJN_Program_Problem_DeveloperName__c == 'additionalActivities') {
                // found the additional activity problem
                additionalActivity = currentCarePlanProblem;
            }

            if (variant.toLowerCase() != 'open') {
                // make a set of existing cases
                Set<String> existingProblems = new Set<String>();
                for (Case problemCase : carePlanProblem.PJN_Cases__r) {
                    existingProblems.add(problemCase.PJN_Program_Case_DeveloperName__c);
                }

                // get all of the program cases configured for this problem
                List<PJN_Program_Case__mdt> programCases = programCaseQuery
                    .queryByProgramProblemDeveloperName(carePlanProblem.PJN_Program_Problem_DeveloperName__c);

                // if the program case doesn't exist add a place holder case wrapper
                // to the problem cases
                for (PJN_Program_Case__mdt programCase : programCases) {
                    if (!existingProblems.contains(programCase.DeveloperName)) {
                        currentCarePlanProblem.cases.add(
                            new PJN_CarePlanCaseWrapper(programCase)
                        );
                    }
                }
            }
            wrappedProblems.add(currentCarePlanProblem);
        }

        // even if there are no additional activites we want to show it so that users can easily create new activities
        if (additionalActivity == null) {
            additionalActivity =  new PJN_CarePlanProblemWrapper(
                new HealthCloudGA__CarePlanProblem__c(Name = Label.PJN_Additional_Activities)
            );
            wrappedProblems.add(additionalActivity);
        }
        for (Case carePlanCase : PJN_CarePlanCaseQuery.queryCasesByCarePlan(carePlanId)) {
            if (variant.toLowerCase() == 'open' && carePlanCase.IsClosed) {
                continue;
            }

            if (carePlanCase.PJN_CarePlan_Problem__c == null) {
                additionalActivity.cases.add(
                    new PJN_CarePlanCaseWrapper(carePlanCase)
                );
            }
        }

        return wrappedProblems;
    }

    /**
     * add fields to query for for the timeline feed config
     * @param   carePlanId        care plan id
     * @returns  Set<String>
     */
    private static Set<String> addTimelineCaseFields(Id carePlanId) {
        String programDeveloperName = [SELECT PJN_Program_DeveloperName__c FROM Case WHERE Id = :carePlanId].PJN_Program_DeveloperName__c;
        Set<String> fields = new Set<String> { 'PJN_Activity_Timeline_Status__c' };
        for(PJN_Care_Plan_Timeline_Case_Field__mdt thisTimelineCaseField : carePlanTimelineCaseFieldQuery.queryByCarePlanProgram(programDeveloperName)) {
            fields.add(thisTimelineCaseField.PJN_Field_API_Name__c);
        }
        return fields;
    }
}