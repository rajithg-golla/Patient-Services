({
    onInit : function(component, event, helper) {
        const record = component.get("v.record");
        const carePlanField = component.get("v.carePlanField");
        component.set("v.fieldValue", record[carePlanField.PJN_Field_API_Name__c]);
    }
});