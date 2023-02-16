/*
 * @author      Mavens
 * @group       CarePlan
 * @description Represents a single care plan and the actions that can be taken on it
 */
public with sharing class PJN_CarePlanWrapper {
    private Case carePlan;
    @TestVisible private Map<Id, HealthCloudGA__CarePlanProblem__c> problems;
    @TestVisible private Map<Id, Case> activities;
    private static Boolean pauseActivityClosedProcessing = false;

    @TestVisible private static String noProblemsToStart = 'Care plan has no problems available to start.';
    @TestVisible private static String problemDoesNotExistOnCarePlan = 'Care plan problem with id {0} not available on this care plan';

    public PJN_CarePlanWrapper(Id carePlanId) {
        this.carePlan = PJN_CarePlanQuery.queryById(carePlanId);
        this.problems = new Map<Id, HealthCloudGA__CarePlanProblem__c>(carePlan.HealthCloudGA__CarePlanProblems__r);
        this.activities = new Map<Id, Case>(carePlan.Cases);
    }

    /*
     * @description Constructor
     * @param       Case - Use PJN_CarePlanQuery class to query cases to get case with all necessary fields and children
     */
    public PJN_CarePlanWrapper(Case carePlan) {
        this.carePlan = carePlan;
        this.problems = new Map<Id, HealthCloudGA__CarePlanProblem__c>(carePlan.HealthCloudGA__CarePlanProblems__r);
        this.activities = new Map<Id, Case>(carePlan.Cases);
    }

    /*
     * @description Start the care plan by starting the first problem unless PJN_Program_Start_Problem__c is set on the care plan
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> start() {
        if (this.problems == null || this.problems.isEmpty()) {
            throw new PJN_CarePlanWrapperException(noProblemsToStart);
        }
        HealthCloudGA__CarePlanProblem__c problemToStart = this.problems.values()[0];
        for ( HealthCloudGA__CarePlanProblem__c problem : this.problems.values()) {
            if (problem.PJN_Program_Problem_DeveloperName__c == this.carePlan.PJN_Program_Start_Problem__c) {
                problemToStart = problem;
                break;
            }
        }
        return startProblem(problemToStart.Id);
    }

    /*
     * @description start problem but get back problem and any cases that need to be updated/created
     * @param       Id - Problem Id to start
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> startProblem(Id problemId) {
        return startProblem(problemId, false);
    }
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> startProblem(Id problemId, Boolean immediateDML) {
        HealthCloudGA__CarePlanProblem__c problem = problems.get(problemId);
        if (problem == null) {
            throw new PJN_CarePlanWrapperException(String.format(problemDoesNotExistOnCarePlan, new List<String>{problemId}));
        }
        PJN_CarePlanProblemHdlr problemHandler = new PJN_CarePlanProblemHdlr(problem);

        Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>> problemCaseMap = problemHandler.start(this.carePlan);

        problem = new List<HealthCloudGA__CarePlanProblem__c>(problemCaseMap.keySet())[0];
        List<PJN_Program_Case__mdt> newProgramCases = problemCaseMap.get(problem);
        List<Case> newActivities = new List<Case>();
        for (PJN_Program_Case__mdt newProgramCase : newProgramCases) {
            PJN_CarePlanCaseHdlr handler = new PJN_CarePlanCaseHdlr(problem, newProgramCase);
            newActivities.add(handler.start());
        }

        if (immediateDML) {
            update problem;
            insert newActivities;
        }

        return new Map<HealthCloudGA__CarePlanProblem__c,List<Case>>{problem => newActivities};
    }


    /*
     * @description skip problem and return problem and cases for further processing
     * @param       Id - Problem Id to start
     * @param       Boolean (default:false/ optional) indicate whether to commit data.
     *              Only pass true outside of bulk context
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> skipProblem(Id problemId, Boolean immediateDML) {
        HealthCloudGA__CarePlanProblem__c problem = problems.get(problemId);
        if (problem == null) {
            throw new PJN_CarePlanWrapperException(String.format(problemDoesNotExistOnCarePlan, new List<String>{problemId}));
        }
        PJN_CarePlanProblemHdlr problemHandler = new PJN_CarePlanProblemHdlr(problem);

        Map<HealthCloudGA__CarePlanProblem__c, List<Case>> problemCaseMap = problemHandler.skip();
        problem = new List<HealthCloudGA__CarePlanProblem__c>(problemCaseMap.keySet())[0];
        update problem;

        pauseActivityClosedProcessing = true;
        update problemCaseMap.get(problem);
        pauseActivityClosedProcessing = false;

        startNextProblem(problem, problemCaseMap);

        if (immediateDML) {
            List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>(problemCaseMap.keySet());
            update problems;
            List<Case> casesToUpsert = new List<Case>();
            for (HealthCloudGA__CarePlanProblem__c currentProblem : problems) {
                casesToUpsert.addAll(problemCaseMap.get(currentProblem));
            }
            upsert casesToUpsert;
        }
        return problemCaseMap;
    }

    /*
     * @description skip problem and return problem and cases for further processing
     * @param       Id - Activity Id that was closed
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> activityClosed(Id activityId) {
        Map<HealthCloudGA__CarePlanProblem__c, List<Case>> returnMap = new Map<HealthCloudGA__CarePlanProblem__c, List<Case>>();
        if (pauseActivityClosedProcessing) {
            return returnMap;
        }
        Case activity = activities.get(activityId);
        List<PJN_Program_Case__mdt> nextProgramCases = PJN_ProgramCase.getNextProgramCasesByProgramProblemDeveloperName(
            activity.PJN_CarePlan_Problem__r.PJN_Program_Problem_DeveloperName__c,
            activity.PJN_Program_Case_DeveloperName__c
        );

        HealthCloudGA__CarePlanProblem__c problem = problems.get(activity.PJN_CarePlan_Problem__c);
        Boolean problemHasNoOpenCases = true;
        for (Case problemActivity : this.carePlan.Cases) {
            if (problemActivity.PJN_CarePlan_Problem__c == problem.Id && problemActivity.Id != activityId && !problemActivity.IsClosed) {
                problemHasNoOpenCases = false;
                break;
            }
        }

        if(problemHasNoOpenCases && (nextProgramCases.isEmpty() || String.isBlank(activity.PJN_Program_Case_DeveloperName__c))) {
            // close out the problem
            PJN_CarePlanProblemHdlr problemHdlr = new PJN_CarePlanProblemHdlr(problem);
            returnMap.put(problemHdlr.close(), new List<Case>());
            startNextProblem(problem, returnMap);
        } else if (String.isNotBlank(activity.PJN_Program_Case_DeveloperName__c)) { // ensure we are working with a care plan activity and not an ad-hoc activity
            for (PJN_Program_Case__mdt programCase : nextProgramCases) {
                PJN_CarePlanCaseHdlr carePlanCaseHdlr = new PJN_CarePlanCaseHdlr(problem, programCase);
                if (!returnMap.containsKey(problem)) {
                    returnMap.put(problem, new List<Case>());
                }
                returnMap.get(problem).add(carePlanCaseHdlr.start());
            }
        }

        return returnMap;
    }

    private void startNextProblem(HealthCloudGA__CarePlanProblem__c problem, Map<HealthCloudGA__CarePlanProblem__c, List<Case>> returnMap) {
        //figure out if next problem needs opening and open if necessary start it
        Boolean hasOpenProblem = false;
        Boolean foundThisProblem = false;
        HealthCloudGA__CarePlanProblem__c nextProblem;
        for (HealthCloudGA__CarePlanProblem__c currentProblem : this.problems.values()) {
            if (currentProblem.PJN_Status__c =='Open' && currentProblem.Id != problem.Id) {
                hasOpenProblem = true;
            }
            if (foundThisProblem && currentProblem.PJN_Status__c == 'Planned'
                    && nextProblem == null && !hasOpenProblem) {
                nextProblem = currentProblem;
            }
            if (currentProblem.Id == problem.Id) {
                // when we find the problem flag it so that the next iteration can mark the "nextProblem"
                foundThisProblem = true;
            }
        }

        if (nextProblem != null) {
            PJN_CarePlanProblemHdlr nextProblemHdlr = new PJN_CarePlanProblemHdlr(nextProblem);
            Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>> returnedData = nextProblemHdlr.start(this.carePlan);
            for (HealthCloudGA__CarePlanProblem__c newProblem : returnedData.keySet()) {
                if (!returnMap.containsKey(newProblem)) {
                    returnMap.put(newProblem, new List<Case>());
                }
                for (PJN_Program_Case__mdt programCase : returnedData.get(newProblem)) {
                    PJN_CarePlanCaseHdlr carePlanCaseHdlr = new PJN_CarePlanCaseHdlr(newProblem, programCase);
                    returnMap.get(newProblem).add(carePlanCaseHdlr.start());
                }
            }
        }
    }

    public class PJN_CarePlanWrapperException extends System.Exception{}
}