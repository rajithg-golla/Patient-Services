({
    init : function(component, event, helper) {
        helper.getAllRecordTypes(component, event, helper);
    },
    getAllRecordTypes : function(component, event, helper) {
        var sObjectName = component.get("v.sObjectName");
        var action = component.get("c.getRecordTypes");
        action.setParams({
            "sObjectName": sObjectName
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response, 
                function(response) {
                    var recordTypes = response.getReturnValue();
                    if(recordTypes.length) {
                        component.set("v.selectedRecordTypeId", recordTypes[0].Id);
                    } else {
                        component.set("v.noRecordTypeSelected", true);
                    }
                    component.set("v.recordTypes", recordTypes);
                }
            );
        });
        $A.enqueueAction(action);
    },
});