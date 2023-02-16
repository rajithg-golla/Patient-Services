({
    onInit : function(component, event, helper) {
        helper.loadCases(component);
    },
    onRefresh : function(component, event, helper) {
        helper.reloadCarePlan(component);
    },
});