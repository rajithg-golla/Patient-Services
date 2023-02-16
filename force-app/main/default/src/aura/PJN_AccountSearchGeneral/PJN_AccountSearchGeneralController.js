({
    doInit : function(component, event, helper) {
        let queryString = window.location.search;
        // parse the query string out this way in lieu of new URLSearchParams not working in locker service
        if (queryString.length) {
            queryString = queryString.substr(1);
        }
        const urlParams = {};
        queryString.split('&').forEach( kv => {
            const parts = kv.split("=");
            urlParams[parts[0]] = parts[1];
        });
        console.log("params",JSON.parse(JSON.stringify(urlParams)));
        if (urlParams.c__phone) {
            component.set("v.phone", urlParams.c__phone);
            component.set("v.incomingCall", true);
        }

        const params = component.get("v.pageReference");
        if(params && params.state) {
            // Set attributes when opened as a tab and the case isn't already set
            if(!component.get("v.activityId")) {
                component.set("v.activityId",  params.state.c__recordId);
                if (params.state.parameters) {
                    helper.setParameters(component, params.state.parameters);
                }
            }
        }

        helper.initialize(component);
        const workspace = component.find("workspace");
        workspace.getEnclosingTabId()
            .then( tabId => {
                workspace.setTabIcon({ tabId, icon: "utility:search"});
                workspace.setTabLabel({tabId, label: "Account Search"});
            });
    },

    enrollPatient: function(component, event, helper) {
        helper.enrollPatient(component);
    },

    retrieveCase: function(component, event, helper) {
        //$A.get("e.force:refreshView").fire();
        helper.retrieveCase(component);
    },

    returnToCase: function(component, event, helper) {
        helper.returnToCase(component);
    }
});