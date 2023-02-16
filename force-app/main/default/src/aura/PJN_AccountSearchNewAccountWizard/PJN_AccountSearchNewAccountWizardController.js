({
    doInit : function(component, event, helper) {
        helper.initialize(component, event, helper);
    },
    addCIRecord : function(component, event, helper) {
        helper.addCIRecord(component, event, helper);
    },
    editCIRecord : function(component, event, helper) {
        helper.editCIRecord(component, event);
    },
    removeCIRecord : function(component, event, helper) {
        helper.removeCIRecord(component, event, helper);
    },
    cancel : function(component) {
        component.set("v.showNewAccountForm", false);
    },
    setFieldSet : function(component, event, helper) {
        helper.setAccountFieldSet(component, event, helper);
    },
    addContactInfoRecord: function(component, event, helper) {
        helper.addContactInfoRecord(component, event, helper);
    },
    submit: function(component, event, helper){
        helper.submit(component, event, helper);
    },
    closeModal: function(component, event) {
        component.set("v.displayAddContactInfo", false);
        const params = event.getParams();
        if (params.index) {
            component.set("v.currentContactInfoIndex", params.index);
        }
    },
    handleSubmittedRecord: function(component, event, helper) {
        helper.handleSubmittedRecord(component, event);
    },
});