({
    build : function(component, header, componentName, componentData) {
        $A.createComponent(
            componentName,
            componentData,
            function(newComponent, status, errorMsg) {
                if(status === "SUCCESS") {
                    component.find("overlayLib").showCustomModal({
                        title: header,
                        body: newComponent,
                        showCloseButton: true
                    });
                } else {
                    let message;
                    switch(status) {
                        case "INCOMPLETE":
                            message = "No response from server - client offline";
                            break;
                        case "ERROR":
                            message = errorMsg;
                            break;
                        default:
                            message = "Unable to build modal";
                    }

                    let noticeParams = {
                        variant: "error",
                        title: status,
                        message: message
                    };
                    try {
                        component.find("notifLib").showToast(noticeParams);
                    } catch(err) {
                        console.log("Unable to display error: ", err);
                        console.log("Parameters: ", JSON.stringify(noticeParams));
                    }
                }
            }
        );
    },

    destroy : function(component) {
        component.find("overlayLib").notifyClose();
    }
});