({
    loadFields : function(component) {
        component.set("v.isLoading", true);
        const carePlan = component.get("v.carePlan");

        if(carePlan) {
            const action = component.get("c.getCarePlanFields");
            action.setParams({
                "carePlanProgramDeveloperName": carePlan.PJN_Program_DeveloperName__c
            });
            action.setCallback(this, function(response) {
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        const carePlanFields = response.getReturnValue();
                        const fields = carePlanFields.map(carePlanField => carePlanField.PJN_Field_API_Name__c);
                        fields.push("Id", "PJN_Program_DeveloperName__c");
                        if(fields.length) {
                            component.set("v.fields", fields);
                        }
                        component.set("v.carePlanFields", carePlanFields);
                        component.set("v.isLoading", false);
                    }
                );
            });
            $A.enqueueAction(action);
        }
    }
});