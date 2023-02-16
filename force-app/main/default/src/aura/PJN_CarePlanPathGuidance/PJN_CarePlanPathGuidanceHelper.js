({
    loadFields : function(component) {
        const componentRecord = component.get("v.componentRecord");
        const action = component.get("c.getCarePlanFields");
        action.setParams({
            "carePlanPathCoachingSettingDeveloperName": componentRecord.DeveloperName
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const carePlanFields = response.getReturnValue();
                    const fields = carePlanFields.map(carePlanField => carePlanField.PJN_Field_API_Name__c);
                    fields.push("Id");
                    if(fields.length) {
                        component.set("v.fields", fields);
                    }
                    component.set("v.carePlanFields", carePlanFields);
                }
            );
        });
        $A.enqueueAction(action);
    }
});