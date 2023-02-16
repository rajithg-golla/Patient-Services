({
    onInit : function(component, event, helper) {
        helper.setStatus(component);
    },
    onHoverProblem : function(component, event, helper) {
        helper.hoverProblem(component);
    },
    onSelectProblem : function(component) {
        const problemSelectionEvent = $A.get("e.c:PJN_CarePlanPathProblemSelection");
        problemSelectionEvent.setParams({
            "selectedProblem" : component.get("v.problemRecord")
        });
        problemSelectionEvent.fire();
    },
    onHandleProblemSelection: function(component, event, helper) {
        const problemRecord = component.get("v.problemRecord");
        const selectedProblem = event.getParam("selectedProblem");
        if(problemRecord && selectedProblem && problemRecord.HealthCloudGA__CarePlan__c === selectedProblem.HealthCloudGA__CarePlan__c) {
            if(problemRecord.Id === selectedProblem.Id) {
                helper.selectThisProblem(component);
            } else {
                helper.deselectThisProblem(component);
            }
        }
    }
});