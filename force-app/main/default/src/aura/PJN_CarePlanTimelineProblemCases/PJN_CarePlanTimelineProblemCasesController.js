({
    onInit : function(component, event, helper) {
        helper.loadCases(component);
    },
    onSelectProblem : function(component, event, helper) {
        helper.selectProblem(component);
    },
    onNewCase : function(component, event, helper) {
        helper.newCase(component);
    }
});