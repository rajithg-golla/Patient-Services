({
    init : function(component) {
        this.getProblems(component);
    },
    getProblems : function(component) {
        component.set("v.isLoading", true);
        const carePlanId = component.get("v.recordId");
        const action = component.get("c.getCarePlanProblems");
        action.setParams({
            "carePlanId": carePlanId
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                response => {
                    const problems = response.getReturnValue();
                    if(problems.length) {
                        component.set("v.problems", problems);
                        const activeProblems = problems.filter(problemRecord => problemRecord.PJN_CarePlan_Path_Status__c === "current");
                        const activeProblem = (activeProblems.length ? activeProblems[0] : undefined);
                        component.set("v.activeProblem", activeProblem);
                        if (activeProblem) {
                            this.fireSelectProblemEvent(component);
                        } else {
                            component.set("v.isLoading", false);
                        }
                    }
                }
            );
        });
        $A.enqueueAction(action);
    },
    fireSelectProblemEvent : function(component) {
        const activeProblem = component.get("v.activeProblem");
        const problemSelectionEvent = $A.get("e.c:PJN_CarePlanPathProblemSelection");
        problemSelectionEvent.setParams({
            "selectedProblem" : activeProblem,
            "context" : component.get("v.context")
        });
        problemSelectionEvent.fire();
    },
    handleProblemSelection : function(component, event) {
        const carePlanId = component.get("v.recordId");
        const selectedProblem = event.getParam("selectedProblem");
        if(carePlanId && selectedProblem && carePlanId === selectedProblem.HealthCloudGA__CarePlan__c) {
            component.set("v.activeProblem", selectedProblem);
            component.set("v.isLoading", false);
        }
    }
});