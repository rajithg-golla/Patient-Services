({
    loadPrograms : function(component) {
        var action = component.get("c.getProgramList");
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response, 
                function(response) {
                    var programList = response.getReturnValue();
                    if (programList.length === 1) {
                        component.set("v.programDeveloperName", programList[0].value);
                        component.set("v.programList", programList);
                        component.find("programSelector").set("v.value", programList[0].value);
                    } else {
                        component.set("v.programList", programList);
                    }
                }
            );
        });
        $A.enqueueAction(action);
    }
});