({
    loadCases : function(component) {
        component.set("v.isLoading", true);
        const carePlanId = component.get("v.recordId");
        const action = component.get("c.getWrappedCarePlanProblems");
        const variant = component.get("v.variant");
        action.setParams({
            carePlanId,
            variant
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const problems = response.getReturnValue();
                    component.set("v.problems", problems);
                    component.set("v.isLoading", false);
                }
            );
        });
        $A.enqueueAction(action);
    },
    reloadCarePlan : function(component) {
        component.find("record").reloadRecord(true);
    }
});