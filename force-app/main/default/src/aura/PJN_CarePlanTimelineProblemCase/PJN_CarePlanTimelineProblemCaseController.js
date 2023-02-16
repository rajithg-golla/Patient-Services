({
    onInit : function(component, event, helper) {
        helper.loadActivitySetting(component);
    },
    onNavigateToCase : function(component, event, helper) {
        helper.navigateToCase(component);
    }
});