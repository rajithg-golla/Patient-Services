({
    onInit : function(component, event, helper) {
        helper.init(component, event, helper);
    },
    onNew : function(component, event, helper) {
        helper.new(component, event, helper);
    },
    onViewAll : function(component, event, helper) {
        helper.viewAll(component, event, helper);
    },
    onHandleRowAction : function(component, event, helper) {
        helper.handleRowAction(component, event, helper);
    }
});