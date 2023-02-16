({
    handleAccountSelection: function(component, event, helper) {
        var account = component.get("v.account");
        var selectAccountEvent = component.getEvent("selectAccountEvent");
        selectAccountEvent.setParams({ 
            selectedId: account.Id 
        });
        selectAccountEvent.fire();
    },
    openAccount: function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.account").Id
        });
        navEvt.fire();
    }
});