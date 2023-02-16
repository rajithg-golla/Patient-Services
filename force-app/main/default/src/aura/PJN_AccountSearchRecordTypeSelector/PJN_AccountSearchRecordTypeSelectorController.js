({
    init : function(component, event, helper) {
        helper.loadPersonRecordTypes(component);
        helper.loadBusinessRecordTypes(component);
        helper.buildSelectedTypes(component);
    },

    setPersonActive : function(component, event, helper) {
        helper.setTab(component, "Person");
    },

    setBusinessActive : function(component, event, helper) {
        helper.setTab(component, "Business");
    },

    setSelectedTypes : function(component, event, helper) {
        helper.buildSelectedTypes(component);
    },

    isPersonAccountSelected : function(component) {
        return component.get("v.selectedAccountType") === "Person";
    },
    
    getSelectedRecordTypes : function(component) {
        return component.get("v.selectedRecordTypes");
    }
});