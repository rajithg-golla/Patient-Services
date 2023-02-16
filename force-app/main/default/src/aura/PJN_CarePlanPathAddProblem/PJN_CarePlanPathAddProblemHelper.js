({
    init : function(component) {
        const programDeveloperName = component.get("v.programDeveloperName");
        const action = component.get("c.getProgramProblemsInLibrary");
        action.setParams({
            "programDeveloperName": programDeveloperName
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const programProblems = response.getReturnValue();
                    component.set("v.programProblems", programProblems);
                }
            );
        });
        $A.enqueueAction(action);
    },
    addProblem : function(component, event) {
        const carePlanId = component.get("v.carePlanId");
        const selectedProgramDeveloperName = event.getParam("value");
        const programProblems = component.get("v.programProblems");
        const programProblem = programProblems.filter(problem => problem.DeveloperName === selectedProgramDeveloperName)[0];
        const confirmed = confirm("Do you really want to add " + programProblem.Label + "?");
        if(confirmed) {
            const action = component.get("c.addProgramProblem");
            action.setParams({
                "carePlanId": carePlanId,
                "programProblem": programProblem
            });
            action.setCallback(this, function(response) {
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        const carePlanProblem = response.getReturnValue();
                        const context = component.get("v.context");
                        if(context) {
                            sforce.one.showToast({
                                title: "Success",
                                type: "success",
                                message: "Successfully added " + carePlanProblem.Name
                            });
                        } else {
                            const toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                title: "Success",
                                type: "success",
                                message: "Successfully added " + carePlanProblem.Name
                            });
                            toastEvent.fire();
                        }
                        $A.get("e.force:refreshView").fire();
                    }
                );
            });
            $A.enqueueAction(action);
        }
    }
});