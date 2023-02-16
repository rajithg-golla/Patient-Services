({
    handleEvent: function(component, event) {
        var recordId = component.get("v.recordId");
        var sourceCaseId = event.getParam("sourceCaseId");
        if (recordId != sourceCaseId) {
            return;
        }

        component.set("v.activeProcesses", component.get("v.activeProcesses") + 1);

        component.set("v.programDeveloperName", event.getParam("programDeveloperName"));
        component.set("v.patientId", event.getParam("patientId"));
        component.set("v.carePlanId", event.getParam("carePlanId"));
        component.set("v.sourceCaseId", event.getParam("sourceCaseId"));
        component.set("v.selectedFileId", event.getParam("selectedFileId"));
        this.showModal(component);

        if (component.get("v.programDeveloperName")) {
            // Create Care Plan
            if (!component.get("v.carePlanId")) {
                this.insertCarePlan(component);
            } else {
                component.set("v.displaySelectProgram", false);
                this.loadSteps(component);
            }
        } else {
            component.set("v.displaySelectProgram", true);
        }

        component.set("v.activeProcesses", component.get("v.activeProcesses") - 1);
    },

    insertCarePlan : function(component) {
        const helper = this;
        component.set("v.activeProcesses", component.get("v.activeProcesses") + 1);

        var action = component.get("c.createCarePlan");
        action.setParams({
            "programDeveloperName": component.get("v.programDeveloperName"),
            "patientId": component.get("v.patientId"),
            "sourceCaseId": component.get("v.sourceCaseId")
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    component.set("v.displaySelectProgram", false);
                    var carePlanId = response.getReturnValue();
                    component.set("v.carePlanId", carePlanId);
                    helper.loadSteps(component);
                }
            );

            component.set("v.activeProcesses", component.get("v.activeProcesses") - 1);
        });
        $A.enqueueAction(action);
    },

    loadSteps : function(component) {
        const helper = this;
        var steps = component.get("v.steps");
        if(!steps.length) {
            component.set("v.activeProcesses", component.get("v.activeProcesses") + 1);

            var programDeveloperName = component.get("v.programDeveloperName");
            var action = component.get("c.getEnrollmentWizardSteps");
            action.setParams({
                "programDeveloperName": programDeveloperName
            });
            action.setCallback(this, function(response) {
                var toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        var steps = response.getReturnValue();
                        component.set("v.steps", steps);
                        helper.setActiveStep(component);
                    }
                );
                component.set("v.activeProcesses", component.get("v.activeProcesses") - 1);
            });
            $A.enqueueAction(action);
        } else {
            this.setActiveStep(component);
        }
    },

    showModal : function(component) {
        var enrollmentWizardComponent = component.find("enrollmentWizard");
        $A.util.removeClass(enrollmentWizardComponent, "slds-hide");
    },

    hideModal : function(component) {
        var enrollmentWizardComponent = component.find("enrollmentWizard");
        $A.util.addClass(enrollmentWizardComponent, "slds-hide");
    },

    setActiveStep : function(component) {
        component.set("v.activeProcesses", component.get("v.activeProcesses") + 1);

        var activeStep = component.get("v.activeStep");
        if(!activeStep) {
            var steps = component.get("v.steps");
            activeStep = steps.filter(stepRecord => stepRecord.PJN_Order__c === 1);
            if(activeStep) {
                component.set("v.activeStep", activeStep[0]);
            }
        } else {
            component.set("v.activeStep", activeStep);
        }
        component.set("v.activeProcesses", component.get("v.activeProcesses") - 1);
    },

    stepEvent: function(component, event) {
        var next = event.getParam("next");
        var previous = event.getParam("previous");
        var refresh = event.getParam("refresh");
        var recordId = event.getParam("recordId");
        if(refresh) {
            if (recordId) {
                component.set("v.recordId", recordId);
            }
            this.refresh(component);
        } else if(next) {
            this.next(component);
        } else if(previous) {
            this.previous(component);
        }
    },

    refresh: function(component) {
        var enrollmentEvent = $A.get("e.c:PJN_EnrollmentWizardEvent");
        enrollmentEvent.setParams({
            "programDeveloperName" : component.get("v.programDeveloperName"),
            "patientId" : component.get("v.patientId"),
            "carePlanId" : component.get("v.carePlanId"),
            "sourceCaseId" : component.get("v.sourceCaseId"),
            "activeStep" : component.get("v.activeStep"),
            "selectedFileId": component.get("v.selectedFileId")
        });
        enrollmentEvent.fire();
    },

    next: function(component) {
        var steps = component.get("v.steps");
        var activeStep = component.get("v.activeStep");
        if (steps.length === activeStep.PJN_Order__c) {
            this.hideModal(component);
            this.openCarePlan(component);
            this.addInitialEnrollmentCompleteDate(component);
        } else {
            var nextStep = steps.filter(stepRecord => stepRecord.PJN_Order__c === activeStep.PJN_Order__c + 1);
            if(nextStep) {
                component.set("v.activeStep", nextStep[0]);
            }
        }
    },

    addInitialEnrollmentCompleteDate : function(component) {
        var action = component.get("c.addInitialEnrollmentCompleteDate");
        action.setParams({
            "carePlanId": component.get("v.carePlanId")
        });
        $A.enqueueAction(action);
    },

    openCarePlan : function(component) {
        const sourceCaseId = component.get("v.sourceCaseId");
        const carePlanId = component.get("v.carePlanId");
        let currentTabId;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo()
            .then(function(response) {
                currentTabId = response.parentTabId;

                return workspaceAPI.openTab({
                    recordId: carePlanId,
                    focus: true
                });
            })
            .then(function(newTab) {
                return workspaceAPI.openSubtab({
                    parentTabId: newTab,
                    focus:false,
                    recordId: sourceCaseId
                });
            })
            .then( function() {
                workspaceAPI.closeTab(currentTabId);
            })
            .catch(function(error) {
                console.log("error", JSON.parse(JSON.stringify(error)));
            });

    },

    previous: function(component) {
        var steps = component.get("v.steps");
        var activeStep = component.get("v.activeStep");
        var displaySelectProgram = component.get("v.displaySelectProgram");
        if (displaySelectProgram || (activeStep && activeStep.PJN_Order__c === 1)) {
            this.closeWizard(component);
        } else {
            var previousStep = steps.filter(stepRecord => stepRecord.PJN_Order__c === activeStep.PJN_Order__c - 1);
            if(previousStep) {
                component.set("v.activeStep", previousStep[0]);
            }
        }
    },

    closeWizard: function(component) {
        var confirmed = confirm($A.get("$Label.c.PJN_Confirm_Exit_Message"));
        if (confirmed) {
            this.hideModal(component);
        }
    },

    fireEnrollmentWizardEvent: function(component) {
        if (!component.get("v.programDeveloperName")) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": $A.get("$Label.c.PJN_No_Valid_Program_Error_Message"),
                "type": "error"
            });
            toastEvent.fire();
        } else {
            var enrollmentEvent = $A.get("e.c:PJN_EnrollmentWizardEvent");
            enrollmentEvent.setParams({
                "programDeveloperName" : component.get("v.programDeveloperName"),
                "patientId" : component.get("v.patientId"),
                "sourceCaseId" : component.get("v.sourceCaseId"),
                "selectedFileId": component.get("v.selectedFileId")
            });
            enrollmentEvent.fire();
        }
    }
});