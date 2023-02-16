({
    loadComponents : function(component, event, helper) {
        var action = component.get("c.getEnrollmentWizardComponents");
        action.setParams({
            "stepId": component.get("v.activeStep").Id
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var wizardComponents = response.getReturnValue();
                    helper.createComponents(component, wizardComponents);
                }
            );
        });
        $A.enqueueAction(action);
    },
    createComponents : function(component, wizardComponents) {
        component.set("v.body", []);

        var carePlanId = component.get("v.carePlanId");
        var sourceCaseId = component.get("v.sourceCaseId");
        var activeStep = component.get("v.activeStep");

        wizardComponents.forEach((componentToLoad) => {
            $A.createComponent(
                "c:" + componentToLoad.PJN_Component_To_Load__c,
                {
                    activeStep: activeStep,
                    activeComponent: componentToLoad,
                    carePlanId: carePlanId,
                    sourceCaseId: sourceCaseId,
                    dirtyComponentMap: component.getReference("v.dirtyComponentMap")
                },
                function(newComponent, status, errorMessage) {
                    if(status === "SUCCESS") {
                        component.set("v.isLoading", false);
                        var body = component.get("v.body");
                        body.push(newComponent);
                        component.set("v.body", body);

                    } else if(status === "INCOMPLETE" || status === "ERROR") {
                        if(errorMessage === null) {
                            errorMessage = "No response from server or client is offline.";
                        }
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error",
                            type: "error",
                            message: errorMessage
                        });
                        toastEvent.fire();
                    }
                }
            );
        });
    },
    setDirtyStepMessage: function(component) {
        const messageMap = component.get("v.dirtyComponentMap");
        const message = Object.values(messageMap).reduce(function(accumulator, currentMessage) {
            if (currentMessage.length) {
                if (accumulator != "") {
                    accumulator += "\n";
                }
                accumulator += currentMessage;
            }
            return accumulator;
        }, "");
        component.set("v.dirtyStepMessage", message);
    }
});