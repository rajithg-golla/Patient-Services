({
    populateFields: function (component, event, helper) {
        var fieldSet = component.get("v.fieldsetAccount");
        var account = component.get("v.account");

        if (account) {
            var allFieldComponents = component.find("newAccountFieldId");
            var map = {};

            if (!Array.isArray(allFieldComponents)) {
                allFieldComponents = [allFieldComponents];
            }
            allFieldComponents.forEach((fieldComponent) => {
                map[fieldComponent.get("v.fieldName")] = fieldComponent;
            });

            fieldSet.forEach((field) => {
                map[field.PJN_Field_API_Name__c].set("v.value", account[field.PJN_Field_API_Name__c]);
            });
        }

        var optionsMap = fieldSet.reduce(
            function (map, field) {
                map[field.PJN_Field_API_Name__c] = field;
                return map;
            },
            {}
        );
        component.set("v.fieldsetAccountByFieldApiNameMap", optionsMap);
    },
    validateData : function(component, event, helper) {
        var fieldSet = component.get("v.fieldsetAccount");
        var fieldSetMap = component.get("v.fieldsetAccountByFieldApiNameMap");

        // Get all inputfield components
        var allFieldComponents = component.find("newAccountFieldId");
        var map = {};
        if (!Array.isArray(allFieldComponents)) {
            allFieldComponents = [allFieldComponents];
        }
        allFieldComponents.forEach((fieldComponent) => {
            map[fieldComponent.get("v.fieldName")] = fieldComponent;
        });

        // Check if all required fields have a value
        var missingData = fieldSet.some((field) => {
            if (fieldSetMap[field.PJN_Field_API_Name__c].PJN_Required__c) {
                if (!map[field.PJN_Field_API_Name__c].get("v.value")) {
                    return true;
                }
            }
        });
        return missingData;
    },
    getSubmittedData: function(component, event, helper) {
        var account={};
        var allFieldComponents = component.find("newAccountFieldId");
        if (!Array.isArray(allFieldComponents)) {
            allFieldComponents = [allFieldComponents];
        }
        allFieldComponents.forEach((fieldComponent) => {
            account[fieldComponent.get("v.fieldName")] = fieldComponent.get("v.value");
        });
        account["RecordTypeId"] = component.get("v.accountRecordTypeId");
        return account;
    },
});