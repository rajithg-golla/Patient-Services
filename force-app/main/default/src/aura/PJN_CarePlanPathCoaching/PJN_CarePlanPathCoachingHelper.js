({
    loadComponentRecords : function(component) {
        const problemRecord = component.get("v.problemRecord");
        if(problemRecord != undefined) {
            const action = component.get("c.getCarePlanPathCoachingSettingsComponent");
            action.setParams({
                "programProblemDeveloperName": problemRecord.PJN_Program_Problem_DeveloperName__c
            });
            action.setCallback(this, function(response) {
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        const componentRecords = response.getReturnValue();
                        component.set("v.componentRecords", componentRecords);
                    }
                );
            });
            $A.enqueueAction(action);
        }
    }
});