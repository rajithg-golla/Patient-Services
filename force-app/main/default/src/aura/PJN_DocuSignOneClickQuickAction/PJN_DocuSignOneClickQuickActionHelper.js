({
    init : function(component) {
        component.set("v.host", window.location.hostname);
        const vfOrigin = "https://" + window.location.hostname.split(".")[0] + "--c.visualforce.com";

        window.addEventListener("message", function(event) {
            if (event.origin !== vfOrigin) {
                // Not the expected origin: Reject the message!
                return;
            }
            const workspaceAPI = component.find("workspaceAPI");
            // the returned url drops the namespace for some reason
            const url = event.data.replace("apex/DocuSign_CreateEnvelope", "apex/dsfs__DocuSign_CreateEnvelope");

            workspaceAPI.getFocusedTabInfo()
                .then(function(response) {
                    //workspaceAPI.closeTab({tabId: focusedTabId});
                    const parentTabId = response.isSubtab ? response.parentTabId : response.tabId;
                    workspaceAPI.openSubtab({
                        parentTabId,
                        url : url + "&" + component.get("v.docuSignParams"),
                        focus: true
                    });
                })
                .catch(function() {
                    component.set("v.errorMessage", "{!$Label.c.PJN_D1C_Error_Opening_Tab)}");
                });

        }, false);

        const recordId = component.get("v.recordId");
        const generateParamsAction = component.get("c.generateEnvelopeParams");

        generateParamsAction.setParams({ recordId });

        generateParamsAction.setCallback(this, function(response) {
            let errors;
            let errorMessage = "{!$Label.c.PJN_D1C_Unknown_Error}";
            switch(response.getState()) {
                case "SUCCESS":
                    component.set("v.docuSignParams", response.getReturnValue());
                    break;
                case "ERROR":
                    errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        errorMessage = errors[0].message;
                    }
                    component.set("v.errorMessage", errorMessage);
                    break;
                default:
                    component.set("v.errorMessage", errorMessage);
            }
        });

        $A.enqueueAction(generateParamsAction);
    }
});