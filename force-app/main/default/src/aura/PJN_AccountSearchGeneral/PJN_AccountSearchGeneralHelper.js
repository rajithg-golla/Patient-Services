({
    initialize : function(component) {
        this.retrieveCase(component);
        this.checkForConfiguredBusinessSearchTypes(component);

        component.set("v.showNewAccountForm", false);
        component.set("v.results",            []);
        component.set("v.account",            {RecordTypeId: ""});
        component.set("v.contactInfo",        {});
        component.set("v.searching",          false);
        component.set("v.searchPerformed",    false);
        component.set("v.selectedFileId",     "");
    },

    retrieveCase : function(component) {
        const retrieveAction = component.get("c.getCase");

        retrieveAction.setParams({
            caseId: component.get("v.activityId")
        });

        retrieveAction.setCallback(this, function(response) {
            component.set("v.case", response.getReturnValue());
            component.set("v.loading", false);
        });

        $A.enqueueAction(retrieveAction);
    },

    // the purpose of this check is to suppress the business search unless there is a configured value
    // to append a new business to on a care plan. If there is no care plan then the search
    // should show the business search.
    checkForConfiguredBusinessSearchTypes: function(component) {
        if (component.get("v.hasBusinessAccounts") && component.get("v.activityId")) {
            // default is true so if false no need to even check for configured records
            const retrieveAction = component.get("c.hasBusinessAccountsConfiguredForCaseSearch");

            retrieveAction.setCallback(this, function(response) {
                const hasConfiguredBusinessTypes = response.getReturnValue();
                component.set("v.hasBusinessAccounts", hasConfiguredBusinessTypes);
            });

            $A.enqueueAction(retrieveAction);
        }
    },

    enrollPatient: function(component) {
        var patientId = component.get("v.case.AccountId");

        const enrollmentEvent = $A.get("e.c:PJN_EnrollmentRequestEvent");
        enrollmentEvent.setParams({
            sourceCaseId: component.get("v.activityId"),
            selectedFileId: component.get("v.selectedFileId"),
            patientId: patientId
        });
        enrollmentEvent.fire();

        // We open the patient tab in the background so that it has time to load
        // and we can open the care plan against it in the correct order when enrollment ends
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "objectApiName": "Account",
                    "recordId": patientId,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: false
        }).catch(function(error) {
            console.log("Error : ", error);
        });
        this.returnToCase(component);
    },

    setParameters: function(component, parameters) {
        Object.entries(parameters).forEach(param => {
            if (component.get("v."+param[0])) {
                component.set("v." + param[0], param[1]);
            }
        });
    },

    returnToCase: function(component) {
        const workspace = component.find("workspace");
        const recordId = component.get("v.pageReference").state.c__recordId;
        const currentWorkspaceTab = component.get("v.pageReference").state.ws;
        const caseUrl = `/lightning/r/Case/${recordId}/view`;

        if(currentWorkspaceTab === caseUrl) {
            workspace.openTab({recordId, focus:true})
                .finally( () => this.closeThisTab(component));
        } else {
            workspace.openSubtab({recordId, focus:true})
                .finally( () => this.closeThisTab(component));
        }
    },

    closeThisTab: function(component) {
        const workspace = component.find("workspace");
        workspace.getEnclosingTabId()
            .then( tabId => workspace.closeTab({ tabId }))
            .catch( error => console.error("Unable to close tab: ", error))
    },
});