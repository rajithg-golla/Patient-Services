({
    init : function(component) {
        this.getCareplans(component);
        this.getAllCarePlanSettings(component);
    },
    getCareplans : function(component) {
        component.set("v.isLoading", true);
        const patientId = component.get("v.patientId");
        const action = component.get("c.getCareplans");
        action.setParams({
            "patientId": patientId
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const careplans = response.getReturnValue();
                    if(careplans.length) {
                        component.set("v.careplans", careplans);
                        component.set("v.isLoading", false);
                    }
                }
            );
        });
        $A.enqueueAction(action);
    },
    getAllCarePlanSettings : function(component) {
        const action = component.get("c.getAllCarePlanSettingsByProgramDeveloperName");
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const allCarePlanSettingsByProgramDeveloperName = response.getReturnValue();
                    component.set("v.allCarePlanSettingsByProgramDeveloperName", allCarePlanSettingsByProgramDeveloperName);
                }
            );
        });
        $A.enqueueAction(action);
    }
});