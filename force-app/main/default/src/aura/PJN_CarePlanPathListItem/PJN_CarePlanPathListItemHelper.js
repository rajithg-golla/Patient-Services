({
    init : function(component) {
        const careplan = component.get("v.careplan");
        const allCarePlanSettingsByProgramDeveloperName = component.get("v.allCarePlanSettingsByProgramDeveloperName");
        const allCareplanSetting = allCarePlanSettingsByProgramDeveloperName[careplan.PJN_Program_DeveloperName__c];
        const title = careplan[allCareplanSetting.PJN_Title_Field_API_Name__c];
        const subtitle = careplan[allCareplanSetting.PJN_Subtitle_Field_API_Name__c];
        component.set("v.allCareplanSetting", allCareplanSetting);
        component.set("v.title", title);
        component.set("v.subtitle", subtitle);
        this.getAllCarePlanSettingFields(component);
    },
    expand : function(component) {
        const isExpanded = component.get("v.isExpanded");
        component.set("v.isExpanded", !isExpanded);
    },
    getAllCarePlanSettingFields : function(component) {
        const allCareplanSetting = component.get("v.allCareplanSetting");
        const allCarePlanSettingDeveloperNames = [allCareplanSetting.DeveloperName];
        const action = component.get("c.getAllCarePlanSettingFieldsBySettingDeveloperName");
        action.setParams({
            "allCarePlanSettingDeveloperNames": allCarePlanSettingDeveloperNames
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponseInContext(
                component.get("v.context"),
                response,
                function(response) {
                    const allCareplanSettingFieldsBySettingDeveloperName = response.getReturnValue();
                    const allCareplanSettingFields = allCareplanSettingFieldsBySettingDeveloperName[allCareplanSetting.DeveloperName];
                    component.set("v.allCareplanSettingFields", allCareplanSettingFields);
                }
            );
        });
        $A.enqueueAction(action);
    },
    navigateToCarePlan : function(component) {
        const careplan = component.get("v.careplan");
        if(careplan) {
            sforce.one.navigateToSObject(careplan.Id);
        }
    }
});