({
    handleCarePlanSelection : function(component, event, helper) {
        if (component.get("v.selected")) {
            component.set("v.selected", false);
        } else {
            component.set("v.selected", true);
        }
        var carePlan = component.get("v.carePlan");
        var selectCarePlanEvent = component.getEvent("selectCarePlanEvent");
        selectCarePlanEvent.setParams({ 
            selectedCarePlan: carePlan
        });
        selectCarePlanEvent.fire();
    },
    openCarePlan : function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.carePlan").Id
        });
        navEvt.fire();
    },
    handleToggleMaster : function(component, event, helper) {
        var carePlan = component.get("v.carePlan");
        var selectMasterCarePlanEvent = $A.get("e.c:PJN_PatientMergeSelectMasterCarePlanEvent");
        selectMasterCarePlanEvent.setParams({ 
            masterCarePlanId: carePlan.Id
        });
        selectMasterCarePlanEvent.fire();
    },
    handleSelectMasterCarePlan : function(component, event, helper) {
        var masterCarePlanId = event.getParam("masterCarePlanId");
        var carePlanId = component.get("v.carePlan").Id;
        if (masterCarePlanId != carePlanId) {
            var masterComponent = component.find("masterToggleId");
            masterComponent.set("v.checked", false); 
        }
    },
});