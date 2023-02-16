({
    init : function(component) {
        const careplan = component.get("v.careplan");
        const allCareplanSettingField = component.get("v.allCareplanSettingField");
        component.set("v.label", allCareplanSettingField.PJN_Field_Label__c);
        component.set("v.value", careplan[allCareplanSettingField.PJN_Field_API_Name__c]);
    },
    navigateToCarePlan : function(component) {
        const careplan = component.get("v.careplan");
        const allCareplanSettingField = component.get("v.allCareplanSettingField");
        const recordId = careplan[allCareplanSettingField.PJN_Link_Record_Id_Field_API_Name__c];
        if(recordId) {
            sforce.one.navigateToSObject(recordId);
        }
    }
});