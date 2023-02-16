({
    onHandleEvent: function(component, event, helper) {
        helper.handleEvent(component, event);
    },
    onStepEvent: function(component, event, helper) {
        helper.stepEvent(component, event);
    },
    onPrevious: function(component, event, helper) {
        helper.previous(component);
    },
    onNext: function(component, event, helper) {
        helper.next(component);
    },
    onCreateCarePlan: function(component, event, helper) {
        helper.fireEnrollmentWizardEvent(component);
    },
    onClose: function(component, event, helper) {
        helper.closeWizard(component);
    }
});