({
    init: function (cmp, event, helper) {
        helper.recordTypeUpdate(cmp);
    },

    handleRTChange : function(component, event, helper) {
        helper.recordTypeUpdate(component);
    },

    submitForm : function(component, event, helper) {
        helper.submitForm(component);
    },

    clearForm : function(component, event, helper) {
        helper.clearForm(component);
    },

    onKeyDown : function(component, event, helper) {
        if (event.key === "Enter") {
            event.preventDefault();
            helper.submitForm(component);
        }
    },
});