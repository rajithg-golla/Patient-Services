({
    onInit: function(component, event, helper) {
        helper.init(component, event, helper);
    },
    onSuccess: function(component, event, helper) {
        helper.success(component, event, helper);
    },
    onError: function(component, event, helper) {
        helper.error(component, event, helper);
    },
    onCancel: function(component, event, helper) {
        helper.cancel(component, event, helper);
    },
    onRefreshEvent: function(component, event, helper) {
        helper.refreshEvent(component, event, helper);
    },
    onSubmit: function(component, event, helper) {
        helper.submit(component, event, helper);
    },
    onChange: function(component, event, helper) {
        helper.change(component, event);
    },
    onLoad: function(component, event, helper) {
        helper.load(component);
    },
});