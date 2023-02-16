({
    init : function(component) {
        const problemRecord = component.get("v.problemRecord");
        const action = component.get("c.getProgramProblem");
        action.setParams({
            "programProblemDeveloperName": problemRecord.PJN_Program_Problem_DeveloperName__c
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const programProblem = response.getReturnValue();
                    component.set("v.programProblem", programProblem);
                }
            );
        });
        $A.enqueueAction(action);
    },
    reloadCarePlan : function(component) {
        component.find("record").reloadRecord(true);
    },
    handleProblemSelection : function(component, event) {
        const problemRecord = component.get("v.problemRecord");
        const selectedProblem = event.getParam("selectedProblem");
        if(problemRecord && selectedProblem && problemRecord.HealthCloudGA__CarePlan__c === selectedProblem.HealthCloudGA__CarePlan__c) {
            if(problemRecord.Id === selectedProblem.Id) {
                component.set("v.isSelected", true);
            } else {
                component.set("v.isSelected", false);
            }
        }
    },
    setVariants :  function(component) {
        const isSelected = component.get("v.isSelected");
        if(isSelected) {
            component.set("v.variantPlay", "inverse");
            component.set("v.variantSkip", "inverse");
            component.set("v.variantDelete", "inverse");
        } else {
            component.set("v.variantPlay", "base");
            component.set("v.variantSkip", "base");
            component.set("v.variantDelete", "base");
        }
    },
    hoverPlay : function(component) {
        component.set("v.variantPlay", "success");
    },
    hoverSkip : function(component) {
        component.set("v.variantSkip", "warning");
    },
    hoverDelete : function(component) {
        component.set("v.variantDelete", "error");
    },
    playProblem : function(component) {
        const problemRecord = component.get("v.problemRecord");
        const confirmed = confirm("Do you really want to start " + problemRecord.Name + "?");
        if(confirmed) {
            component.set("v.awaitingCompletion", true);
            const action = component.get("c.startCarePlanProblem");
            action.setParams({
                "carePlanProblem": problemRecord
            });
            action.setCallback(this, function(response) {
                if (response.getState() !== "SUCCESS") {
                    component.set("v.awaitingCompletion", false);
                }
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function() {
                        const context = component.get("v.context");
                        if(context) {
                            sforce.one.showToast({
                                title: "Success",
                                type: "success",
                                message: "Sucessfully started " + problemRecord.Name
                            });
                        }
                    }
                );
            });
            $A.enqueueAction(action);
        }
    },
    skipProblem : function(component) {
        const problemRecord = component.get("v.problemRecord");
        const confirmed = confirm("Do you really want to skip " + problemRecord.Name + "?");
        if(confirmed) {
            component.set("v.awaitingCompletion", true);
            const action = component.get("c.skipCarePlanProblem");
            action.setParams({
                "carePlanProblem": problemRecord
            });
            action.setCallback(this, function(response) {
                if (response.getState() !== "SUCCESS") {
                    component.set("v.awaitingCompletion", false);
                }
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function() {
                        const context = component.get("v.context");
                        if(context) {
                            sforce.one.showToast({
                                title: "Success",
                                type: "success",
                                message: "Sucessfully skipped " + problemRecord.Name
                            });
                        }
                    }
                );
            });
            $A.enqueueAction(action);
        }
    },
    deleteProblem : function(component) {
        component.set("v.awaitingCompletion", true);
        const problemRecord = component.get("v.problemRecord");
        const confirmed = confirm("Do you really want to delete " + problemRecord.Name + "?");
        if(confirmed) {
            const action = component.get("c.deleteCarePlanProblem");
            action.setParams({
                "carePlanProblem": problemRecord
            });
            action.setCallback(this, function(response) {
                if (response.getState() !== "SUCCESS") {
                    component.set("v.awaitingCompletion", false);
                }
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function() {
                        const context = component.get("v.context");
                        if(context) {
                            sforce.one.showToast({
                                title: "Success",
                                type: "success",
                                message: "Sucessfully deleted " + problemRecord.Name
                            });
                        }
                    }
                );
            });
            $A.enqueueAction(action);
        }
    }
});