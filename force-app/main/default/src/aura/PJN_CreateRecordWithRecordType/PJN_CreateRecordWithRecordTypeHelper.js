({
    create : function(component, event, helper) {
        var sObjectName = component.get("v.sObjectName");
        var selectedRecordTypeId = component.get("v.selectedRecordTypeId");
        var defaultFieldValues = component.get("v.defaultFieldValues");
        var createEvent = $A.get("e.force:createRecord");
        createEvent.setParams({
            "entityApiName": sObjectName,
            "recordTypeId": selectedRecordTypeId,
            "defaultFieldValues": defaultFieldValues
        });
        createEvent.fire();
        helper.cancel(component, event, helper);
    },
    cancel : function(component, event, helper) {
        component.set("v.show", false);
    }
});