({
    onInit : function(component) {
        const caseWrapper = component.get("v.caseWrapper");
        const activityFieldSetting = component.get("v.activityFieldSetting");
        let fieldValue;
        if (!caseWrapper) {
            return;
        }
        if(caseWrapper.activityType === "planned'") {
            fieldValue = activityFieldSetting.PJN_Field_Label__c + " " + caseWrapper.programCase[activityFieldSetting.PJN_Field_API_Name__c];
        } else {
            fieldValue = activityFieldSetting.PJN_Field_Label__c + " " + caseWrapper.caseRecord[activityFieldSetting.PJN_Field_API_Name__c];
        }
        component.set("v.fieldValue", fieldValue);
    }
});