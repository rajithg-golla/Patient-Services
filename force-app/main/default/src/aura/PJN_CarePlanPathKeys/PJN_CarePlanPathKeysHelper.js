({
    init : function(component) {
        const componentRecord = component.get("v.componentRecord");
        const action = component.get("c.getCarePlanPathKeyFieldsSetting");
        action.setParams({
            "carePlanPathCoachingSettingDeveloperName": componentRecord.DeveloperName
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const setting = response.getReturnValue();
                    component.set("v.carePlanPathKeysSetting", setting);
                    component.set("v.fields", setting.PJN_Fields__c.split(","));
                    component.set("v.columns", setting.PJN_Columns__c);
                }
            );
        });
        $A.enqueueAction(action);
    }
});