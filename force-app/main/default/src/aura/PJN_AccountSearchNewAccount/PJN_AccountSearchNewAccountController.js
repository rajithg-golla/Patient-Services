({
    handleLoad: function (component, event, helper) {
        helper.populateFields(component, event, helper);
    },
    validateData: function (component, event, helper) {
        return helper.validateData(component, event, helper);
    },
    getSubmittedData: function(component, event, helper) {
        return helper.getSubmittedData(component, event, helper);
    },
    handleFieldChange: function (component, event, helper) {
        let fieldName = event.getSource().get("v.fieldName") ;
        let newValue =  event.getSource().get("v.value") ;

        const account = component.get("v.account");
        account[fieldName] = newValue;
        component.set("v.account", account);
    }
});