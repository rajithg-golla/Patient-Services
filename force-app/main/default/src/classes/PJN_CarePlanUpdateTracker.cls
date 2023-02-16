public with sharing class PJN_CarePlanUpdateTracker implements PJN_TriggerDispatcher.HandlerInterface {

    private Set<Id> carePlanIds;

    /*
     * @description handle the trigger. get the first record from the correct trigger list
     *              and route to the correct logic. Publish the correct events
     */
    public void handle() {
        carePlanIds = new Set<Id>();
        SObject firstObject;
        if (Trigger.isDelete) {
            firstObject =Trigger.old[0];
        } else {
            firstObject =Trigger.new[0];
        }

        if (firstObject.getSobjectType() == PJN_Care_Plan_Update__e.getSobjectType()) {
            handlePlatformEvents();
            return; // don't need to publish anything
        } else if (firstObject.getSobjectType() == Case.getSobjectType()) {
            handleCases();
        } else if (firstObject.getSObjectType() == HealthCloudGA__CarePlanProblem__c.getSobjectType()) {
            handleCarePlanProblems();
        }

        List<PJN_Care_Plan_Update__e> carePlanUpdateEvents = new List<PJN_Care_Plan_Update__e>();

        for (Id carePlanId : carePlanIds) {
            carePlanUpdateEvents.add(
                new PJN_Care_Plan_Update__e (
                    PJN_Care_Plan_Id__c = carePlanId,
                    PJN_Intermediate_Event__c = true
                )
            );
        }
        EventBus.publish(carePlanUpdateEvents);
    }

    /*
     * @description loop over cases, if parent exists add to list, otherwise add case id
     */
    private void handleCases() {
        List<Case> cases;
        if (Trigger.isDelete) {
            cases = (List<Case>) Trigger.old;
        } else {
            cases = (List<Case>) Trigger.new;
        }
        for (Case currentCase : cases) {
            if (currentCase.ParentId == null) {
                carePlanIds.add(currentCase.id);
            } else {
                carePlanIds.add(currentCase.ParentId);
            }
        }
    }

    /*
     * @description loop over care plan problems, add care plan id to set
     */
    private void handleCarePlanProblems() {
        List<HealthCloudGA__CarePlanProblem__c> problems;
        if (Trigger.isDelete) {
            problems = (List<HealthCloudGA__CarePlanProblem__c>) Trigger.old;
        } else {
            problems = (List<HealthCloudGA__CarePlanProblem__c>) Trigger.new;
        }

        for (HealthCloudGA__CarePlanProblem__c problem : problems) {
            carePlanIds.add(problem.HealthCloudGA__CarePlan__c);
        }
    }

    /*
     * @description loop over platform events. If the care plan update is intermediate then add
     *              its care plan id to a set of strings then aggregate them all to a single event
     */
    private void handlePlatformEvents() {
        Set<String> carePlanIds = new Set<String>();
        for (PJN_Care_Plan_Update__e event : (List<PJN_Care_Plan_Update__e>) Trigger.new) {
            if (event.PJN_Intermediate_Event__c) {
                carePlanIds.add(event.PJN_Care_Plan_Id__c);
            }
        }

        if (!carePlanIds.isEmpty()) {
            List<String> carePlanIdsList = new List<String>(carePlanIds);
            PJN_Care_Plan_Update__e event = new PJN_Care_Plan_Update__e(
                PJN_Care_Plan_Ids_List__c = String.join(carePlanIdsList, ';')
            );
            EventBus.publish(event);
        }
    }
}