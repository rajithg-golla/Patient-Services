({
    loadCases : function(component) {
        const carePlanProblem = component.get("v.carePlanProblem");
        component.set("v.cases", carePlanProblem.cases);

        const getRecordTypeIdAction = component.get("c.getRecordTypeId");
        getRecordTypeIdAction.setParams({
            "developerName": "PJN_Activity"
        });
        getRecordTypeIdAction.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    component.set("v.activityRecordTypeId", response.getReturnValue());
                }
            );
        });
        $A.enqueueAction(getRecordTypeIdAction);
    },
    selectProblem: function(component) {
        const problemSelectionEvent = $A.get("e.c:PJN_CarePlanPathProblemSelection");
        problemSelectionEvent.setParams({
            "selectedProblem" : component.get("v.carePlanProblem")
        });
        problemSelectionEvent.fire();
    },
    newCase: function(component) {
        const carePlan = component.get("v.carePlan");
        const carePlanProblem = component.get("v.carePlanProblem") && component.get("v.carePlanProblem").detail;
        const createCaseEvent = $A.get("e.force:createRecord");
        const parameters = {
            "entityApiName": "Case",
            "recordTypeId": component.get("v.activityRecordTypeId"),
            "defaultFieldValues": {
                "ParentId" : (carePlanProblem.Id ? carePlanProblem.HealthCloudGA__CarePlan__c : carePlan.Id),
                "AccountId" : (carePlanProblem.Id ? carePlanProblem.HealthCloudGA__CarePlan__r.AccountId : carePlan.AccountId),
                "PJN_Program_DeveloperName__c" : carePlan.PJN_Program_DeveloperName__c
            }
        };
        if (carePlanProblem.Id) {
            parameters.defaultFieldValues.PJN_CarePlan_Problem__c = carePlanProblem.Id;
        }
        createCaseEvent.setParams(parameters);
        createCaseEvent.fire();
    }
});