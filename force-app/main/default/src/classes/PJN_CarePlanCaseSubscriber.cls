public with sharing class PJN_CarePlanCaseSubscriber implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handle before insert trigger context
     */
    public void handle() {
        handleClosedCases(
            (Map<Id, Case>) trigger.oldMap,
            (Map<Id, Case>) trigger.newMap
        );
    }
    /**
     * handle closed cases
     * @param   Map<Id, Case> oldCaseMap
     * @param   Map<Id, Case> newCaseMap
     */
    private void handleClosedCases(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        Map<Id, Case> casesWithFieldsMap = PJN_CarePlanCaseQuery.queryByIds(newCaseMap.keySet());
        List<Case> closedCases = new List<Case>();
        Set<Id> carePlanIds = new Set<Id>();
        for(Id thisCaseId : newCaseMap.keySet()) {
            if(newCaseMap.get(thisCaseId).AccountId != null
                    && newCaseMap.get(thisCaseId).ParentId != null
                    && newCaseMap.get(thisCaseId).PJN_CarePlan_Problem__c != null
                    && caseHasBeenClosed(oldCaseMap.get(thisCaseId), newCaseMap.get(thisCaseId))) {
                closedCases.add(casesWithFieldsMap.get(thisCaseId));
                carePlanIds.add(casesWithFieldsMap.get(thisCaseId).ParentId);
            }
        }

        if(!closedCases.isEmpty()) {
            Map<Id, PJN_CarePlanWrapper> carePlans = new Map<Id, PJN_CarePlanWrapper>();
            for (Case crPln : PJN_CarePlanQuery.queryByIds(carePlanIds).values()) {
                carePlans.put(crPln.Id, new PJN_CarePlanWrapper(crPln));
            }

            Map<HealthCloudGA__CarePlanProblem__c, List<Case>> problemToCasesMap = new Map<HealthCloudGA__CarePlanProblem__c, List<Case>>();
            for (Case closedCase : closedCases) {
                PJN_CarePlanWrapper wrapper = carePlans.get(closedCase.ParentId);
                Map<HealthCloudGA__CarePlanProblem__c, List<Case>> dataToUpdate = wrapper.activityClosed(closedCase.Id);
                for (HealthCloudGA__CarePlanProblem__c problem : dataToUpdate.keySet()) {
                    if (!problemToCasesMap.containsKey(problem)) {
                        problemToCasesMap.put(problem, new List<Case>());
                    }
                    problemToCasesMap.get(problem).addAll(dataToUpdate.get(problem));
                }
            }

            List<HealthCloudGA__CarePlanProblem__c> problemsToUpsert = new List<HealthCloudGA__CarePlanProblem__c> (
                problemToCasesMap.keySet()
            );
            List<Case> casesToUpsert = new List<Case>();
            for (HealthCloudGA__CarePlanProblem__c problem : problemToCasesMap.keySet()) {
                casesToUpsert.addAll(problemToCasesMap.get(problem));
            }

            upsert problemsToUpsert;
            upsert casesToUpsert;
        }
    }

    /**
     * handle closed cases
     * @param   Case oldCase
     * @param   Case newCase
     * @returns  Boolean
     */
    private Boolean caseHasBeenClosed(Case oldCase, Case newCase) {
        return !oldCase.IsClosed && newCase.IsClosed;
    }
}