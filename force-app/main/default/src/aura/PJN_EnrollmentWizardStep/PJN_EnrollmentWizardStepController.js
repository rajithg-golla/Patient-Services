({
    onActiveStepChange : function(component, event, helper) {
        helper.loadComponents(component, event, helper);
    },
    onDirtyComponentMapChange: function(component, event, helper) {
        helper.setDirtyStepMessage(component);
    }
});