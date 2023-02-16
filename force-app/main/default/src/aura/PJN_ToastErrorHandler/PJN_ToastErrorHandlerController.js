({
    handleResponse : function(component, event) {
        const params = event.getParam("arguments");
        const context = params.context;
        const response = params.response;
        const successHandler = params.successHandler;
        const errorHandler = params.errorHandler;

        var state = response.getState();

        if(state == "SUCCESS") {
            successHandler(response);
        } else {
            var message = "";

            if (state === "INCOMPLETE") {
                message = "Server could not be reached. Check your internet connection.";
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    for(var i=0; i < errors.length; i++) {
                        for(var j=0; errors[i].pageErrors && j < errors[i].pageErrors.length; j++) {
                            message += (message.length > 0 ? "\n" : "") + errors[i].pageErrors[j].message;
                        }
                        if(errors[i].fieldErrors) {
                            for(var fieldError in errors[i].fieldErrors) {
                                var thisFieldError = errors[i].fieldErrors[fieldError];
                                for(var k=0; k < thisFieldError.length; k++) {
                                    message += (message.length > 0 ? "\n" : "") + thisFieldError[k].message;
                                }
                            }
                        }
                        if(errors[i].message) {
                            message += (message.length > 0 ? "\n" : "") + errors[i].message;
                        }
                    }
                } else {
                    message += (message.length > 0 ? "\n" : "") + "Unknown error";
                }
            }

            console.log("context", context);
            if(context) {
                sforce.one.showToast({
                    title: "Error",
                    type: "error",
                    message: message
                });
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error",
                    type: "error",
                    message: message
                });
                toastEvent.fire();
            }

            if(errorHandler) {
                errorHandler(response);
            }
        }
    }
});