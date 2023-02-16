({
    doInit : function(component, event, helper) {
        helper.getFilesListOptions(component);
    },

    handleFileChange : function(component, event, helper) {
        helper.handleFileChange(component);
    }
});