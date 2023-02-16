({
    doInit : function(component, event, helper) {
        helper.initialize(component);
    },

    onRemove : function(component, event, helper) {
        helper.remove(component, event, helper);
    },

    onNavigateToRecord : function(component, event, helper) {
        helper.navigateToRecord(component, event, helper);
    }
});