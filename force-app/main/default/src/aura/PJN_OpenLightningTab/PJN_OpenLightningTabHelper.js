({
    buildParameters : function(component) {
        // When custom parameters are present, transform them into an object
        let paramString = component.get("v.parameters");
        let paramMap = {};

        if(paramString) {
            paramMap = JSON.parse("{" + paramString + "}");
        }

        return paramMap;
    },

    openTarget : function(component) {
        // Prepare the params common to both primary and sub tabs
        let parameters = {
            pageReference: {
                "type": "standard__component",
                "attributes": {
                    "componentName": "c__" + component.get("v.target").trim()
                },
                "state": {
                    recordId:    component.get("v.recordId"),
                    returnUrl:   component.get("v.returnUrl"),
                    returnTabId: component.get("v.thisTabId"),
                    parameters:  this.buildParameters(component)
                }
            },
            focus: true
        };

        // Open the tab or subtab as appropriate
        if(component.get("v.isTargetSubtab")) {
            // Indicate the parent tab and open the subtab
            parameters.parentTabId = component.get("v.thisTabId");
            this.openSubtab(component, parameters);
        } else {
            this.openTab(component, parameters);
        }
    },

    openTab : function(component, parameters) {
        const workspace = component.find("workspace");

        workspace.openTab(parameters).then(function(response) {
            component.set("v.targetTabId", response);
            workspace.setTabLabel({tabId: response, label: component.get("v.displayName")});
        }).catch(function(error) {
            console.log(error);
        });
    },

    openSubtab : function(component, parameters) {
        const parentTabId = component.get("v.thisTabId");
        const workspace   = component.find("workspace");

        workspace.openSubtab(parameters).then(function(response) {
            component.set("v.targetTabId", response);
            workspace.setTabLabel({tabId: response, label: component.get("v.displayName")});


            // Get the browser tab to show the correct label (instead of "Loading...")
            workspace.focusTab({tabId : parentTabId});
            setTimeout(
                function() { workspace.focusTab({tabId : response});},
                0
            );
        }).catch(function(error) {
            console.log(error);
        });
    }
});