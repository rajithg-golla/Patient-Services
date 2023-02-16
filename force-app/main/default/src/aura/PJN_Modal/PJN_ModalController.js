({
    openModal : function(component, event, helper) {
        const params = event.getParam("arguments");
        helper.build(component, params.header, params.componentName, params.componentData);
    },

    closeModal : function(component, event, helper) {
        helper.destroy(component);
    }
});