({
    handleSelectCarePlan : function(component, event, helper) {
        var idList = component.get("v.selectedCarePlanIdList");
        var carePlanId = event.getParam("selectedCarePlan").Id;
        if (idList.includes(carePlanId)) {
            var index = idList.indexOf(carePlanId);
            if (index !== -1) idList.splice(index, 1);
        } else {
            idList.push(carePlanId);
        }
        component.set("v.selectedCarePlanIdList", idList);
        var masterCarePlanId = component.get("v.masterCarePlanId");
        if (!idList || idList.length < 2 || !masterCarePlanId) {
            component.set("v.disableMergeCarePlansButton", true);
        } else {
            component.set("v.disableMergeCarePlansButton", false);
        }
    },
    displayChildRecords : function(component, event, helper) {
        var selectedCarePlanIdsList = component.get("v.selectedCarePlanIdList");
        var masterCarePlanId = component.get("v.masterCarePlanId");
        if (!selectedCarePlanIdsList || selectedCarePlanIdsList.length < 2 || !masterCarePlanId) {
            var errorToastEvent = $A.get("e.force:showToast");
            errorToastEvent.setParams({
                title: "Error",
                type: "error",
                message: $A.get("$Label.c.PJN_Patient_Merge_Tool_Select_Care_Plan_Error")
            });
            errorToastEvent.fire();
            return;
        }

        var carePlanList = component.get("v.carePlanList");
        const selectedCarePlans = carePlanList.filter(item => selectedCarePlanIdsList.includes(item.Id));
        const masterCarePlan = carePlanList.filter(item => masterCarePlanId == item.Id)[0];
        component.set("v.selectedCarePlans", selectedCarePlans);
        component.set("v.masterCarePlan", masterCarePlan);

        var actionGetChildRecords = component.get("c.getChildRecords");
        actionGetChildRecords.setParams({
            carePlanIdsList: component.get("v.selectedCarePlanIdList")
        });
        actionGetChildRecords.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            component.set("v.childRecordList", resp);
        });
        $A.enqueueAction(actionGetChildRecords);

        component.set("v.showCarePlanSelectionScreen", false);
        component.set("v.showChildRecordsSelectionScreen", true);

        // Hide Back and Next button
        var hideButtonsEvent = component.getEvent("hideButtonsEvent");
        hideButtonsEvent.setParams({
            "hide": true
        });
        hideButtonsEvent.fire();
    },
    handleSelectMasterCarePlan : function(component, event, helper) {
        var masterCarePlanId = event.getParam("masterCarePlanId");
        if (component.get("v.masterCarePlanId") === masterCarePlanId) {
            masterCarePlanId = null;
        }
        component.set("v.masterCarePlanId", masterCarePlanId);
        var idList = component.get("v.selectedCarePlanIdList");
        if (!idList || idList.length < 2 || !masterCarePlanId) {
            component.set("v.disableMergeCarePlansButton", true);
        } else {
            component.set("v.disableMergeCarePlansButton", false);
        }
    },
    handleMergeChildRecordsEvent : function(component, event, helper) {
        var carePlanList = component.get("v.carePlanList");
        var masterCarePlanId = event.getParam("masterCarePlanId");
        var selectedCarePlanIdList = event.getParam("selectedCarePlanIdList");
        const keepers = carePlanList.filter(item => !selectedCarePlanIdList.includes(item.Id) || item.Id === masterCarePlanId);
        component.set("v.carePlanList", keepers);
        component.set("v.selectedCarePlanIdList", []);
        component.set("v.masterCarePlanId", null);
        component.set("v.showCarePlanSelectionScreen", true);
        component.set("v.showChildRecordsSelectionScreen", false);
        component.set("v.disableMergeCarePlansButton", true);

        // Send CarePlanList to parent
        var updateCarePlanListEvent = component.getEvent("updateCarePlanListEvent");
        updateCarePlanListEvent.setParams({
            "carePlanList": keepers
        });

        updateCarePlanListEvent.fire();
    },
});