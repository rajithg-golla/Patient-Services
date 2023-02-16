({
    initialize : function(component) {
        const action = component.get("c.getFieldUpdateability");
        action.setStorable();
        action.setParams({ objectName: "Case" });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                response => component.set(
                    "v.isUpdateable",
                    response.getReturnValue()[component.get("v.caseField")]
                )
            );
        });
        $A.enqueueAction(action);
    },

    remove : function(component) {
        const currentCase = component.get("v.case");
        const field = component.get("v.caseField");
        currentCase[field] = null;
        if (field == "AccountId") {
            currentCase.ParentId = null;
        }

        if (field == "PJN_Physician__c") {
            currentCase.PJN_Enrollment_Address__c = null;
        }

        const removeAction = component.get("c.updateCase");
        removeAction.setParams({ currentCase });
        removeAction.setCallback(this, function(response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.case", response.getReturnValue());
            }
        });
        $A.enqueueAction(removeAction);
    },
    navigateToRecord : function(component) {
        const currentCase = component.get("v.case");
        const field = component.get("v.caseField");
        const recordId = currentCase[field];
        if(recordId) {
            var navigationEvent = $A.get("e.force:navigateToSObject");
            navigationEvent.setParams({
                "recordId": recordId,
                "slideDevName": "detail"
            });
            navigationEvent.fire();
        }
    }
});