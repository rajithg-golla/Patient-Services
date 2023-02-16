({
    init : function(component, event, helper) {
        helper.getPlans(component);
    },

    handleCarePlanEvent : function(component, event, helper) {
        const recordId = event.getParam("id");
        helper.setCarePlan(component, recordId);
    },

    skipPlan : function(component, event, helper) {
        let noticeParams = {
            variant: "success",
            title: $A.get("$Label.c.PJN_Success_Title_Notification"),
            message: $A.get("$Label.c.PJN_Patient_selected_success_message")
        };
        component.find("notifLib").showToast(noticeParams);
        helper.finished(component);
    }
});