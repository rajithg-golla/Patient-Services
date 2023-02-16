({
    mergeChildRecords : function(component, event, helper) {
        // For files and notes
        var setMergedCarePlansEvent = $A.get("e.c:PJN_PatientMergeSetMergedCarePlanIdsEvent");
        setMergedCarePlansEvent.setParams({
            selectedCarePlanIdList: component.get("v.selectedCarePlanIdList"),
            masterCarePlanId: component.get("v.masterCarePlanId")
        });
        setMergedCarePlansEvent.fire();


        var mergeChildRecordsEvent = component.getEvent("mergeChildRecordsEvent");
        mergeChildRecordsEvent.setParams({
            selectedCarePlanIdList: component.get("v.selectedCarePlanIdList"),
            masterCarePlanId: component.get("v.masterCarePlanId")
        });
        mergeChildRecordsEvent.fire();

        // Hide Back and Next button
        var hideButtonsEvent = component.getEvent("hideButtonsEvent");
        hideButtonsEvent.setParams({
            "hide": false
        });
        hideButtonsEvent.fire();
    },
    displayMergeCarePlanScreen : function(component, event, helper) {
        var mergeChildRecordsEvent = component.getEvent("mergeChildRecordsEvent");
        mergeChildRecordsEvent.setParams({
            selectedCarePlanIdList: [],
            masterCarePlanId: null
        });
        mergeChildRecordsEvent.fire();

        // Hide Back and Next button
        var hideButtonsEvent = component.getEvent("hideButtonsEvent");
        hideButtonsEvent.setParams({
            "hide": false
        });
        hideButtonsEvent.fire();

        // Reset childRecords
        var selectChildRecordEvent = component.getEvent("selectChildRecordEvent");
        selectChildRecordEvent.setParams({
            masterCarePlanId: component.get("v.masterCarePlanId"),
            selectedRecordList: [] 
        });
        selectChildRecordEvent.fire();
    },

});