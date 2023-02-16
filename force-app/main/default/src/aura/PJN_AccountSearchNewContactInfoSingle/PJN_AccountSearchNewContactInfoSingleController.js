({
    doInit : function(component) {
        const contactInfo = component.get("v.contactInfoRecord");
        const recordType = component.get("v.recordTypesMap")[contactInfo.RecordTypeId];
        component.set("v.recTypeName", recordType.label);
        const fieldset = component.get("v.fieldsetContactInfoMap")[recordType.developerName];
        component.set("v.fieldsetContactInfo", fieldset);
    },

    removeContactInfoRec : function(component, event, helper) {
        helper.removeContactInfoRec(component, event, helper);
    },

    editRecord: function (component, event, helper) {
        helper.editRecord(component);
    }
});