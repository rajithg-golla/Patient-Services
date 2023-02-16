({
    navigateToCase : function(component) {
        const caseWrapper = component.get("v.caseWrapper");
        const sObectEvent = $A.get("e.force:navigateToSObject");
        sObectEvent .setParams({
            "recordId": caseWrapper.caseRecord.Id,
            "slideDevName": "detail"
        });
        sObectEvent.fire();
    },
    loadActivitySetting : function(component) {
        const caseWrapper = component.get("v.caseWrapper");
        const programDeveloperName = component.get("v.programDeveloperName");
        const action = component.get("c.getActivitySettings");
        action.setParams({
            "programDeveloperName": programDeveloperName,
            "activityType": caseWrapper.activityType
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const activitySetting = response.getReturnValue().activitySetting;
                    const activityFieldSettings = response.getReturnValue().activityFieldSettings;
                    if(activityFieldSettings) {
                        component.set("v.activityFieldSettings", activityFieldSettings);
                    }
                    component.set("v.iconName", activitySetting.PJN_Icon_Name__c);
                    let ownerName = "";
                    if(caseWrapper.caseRecord && caseWrapper.caseRecord.Owner.Name) {
                        ownerName = caseWrapper.caseRecord.Owner.Name;
                    } else if(caseWrapper.caseRecord) {
                        ownerName = caseWrapper.caseRecord.Owner.FirstName + " " + caseWrapper.caseRecord.Owner.LastName;
                    }
                    component.set("v.ownerName", ownerName);
                }
            );
        });
        $A.enqueueAction(action);
    }
});