({
    onInit : function(component, event, helper) {
        var action = component.get("c.submitFulfillmentRecord");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            $A.get("e.force:closeQuickAction").fire();
            var toastEvent = $A.get("e.force:showToast");
            var type = "success";
            var title = "Success";
            var mode = "dismissable";
            var message = $A.get("$Label.c.PJN_Fulfillment_Submission_Success_Message");

            if (response.getState() != "SUCCESS" || !response.getReturnValue()) {
                type = "error";
                title = "Error";
                mode = "sticky"

                // The record has already been submitted
                if (response.getState() == "SUCCESS") {
                    message = $A.get("$Label.c.PJN_Fulfillment_Submission_Error_Already_Submited_Message");
                } else {
                    message = "Unknown Error";
                    var errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message = errors[0].message;
                    }
                }
            } else {
                $A.get("e.force:refreshView").fire();
            }
            toastEvent.setParams({
                type: type,
                title: title,
                message: message,
                mode: mode
            });
            toastEvent.fire();
        });
        $A.enqueueAction(action);
    }
});