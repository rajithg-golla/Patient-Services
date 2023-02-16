({
    doInit : function(component) {
        const fieldSetting = component.get("v.fieldSetting");
        const contactInfoRecord = component.get("v.contactInfoRecord");
        const valueKey = component.get("v.valueKey");

        component.set("v.label", fieldSetting["MasterLabel"]);
        component.set("v.value", contactInfoRecord[valueKey]);
        component.set("v.type", fieldSetting["PJN_Type__c"]);
    },
});