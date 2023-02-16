({
    assign : function(component) {
        const recordId = component.get("v.recordId");
        const action = component.get("c.assignSpecialtyPharmacy");
        action.setParams({recordId});
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function() {
                    const toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Success",
                        type: "success",
                        message: "Successfully assiged Pharmacy"
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