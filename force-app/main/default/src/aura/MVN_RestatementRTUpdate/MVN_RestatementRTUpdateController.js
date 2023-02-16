({
    onInit : function(component) {
        const action = component.get("c.switchRT");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                () => {
                    const toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: "success",
                        title: "Success",
                        message: $A.get("$Label.c.MVN_Restatement_RT_Success")
                    });
                    toastEvent.fire();
                    $A.get("e.force:refreshView").fire();
                }
            );
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
});