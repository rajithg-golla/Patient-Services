({
    initialize : function(component, event, helper) {
        component.set("v.isLoading", true);
        if (!component.get("v.contactInfo")["PJN_Country__c"]) {
            const getUserCountryAction = component.get("c.getUserCountry");
            getUserCountryAction.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    component.set("v.defaultCountry", response.getReturnValue());
                }
            });
            $A.enqueueAction(getUserCountryAction);
        } else {
            component.set("v.defaultCountry", component.get("v.contactInfo")["PJN_Country__c"]);
        }
        component.set("v.accountRecordTypeId", component.get("v.account.RecordTypeId"));

        if (!component.get("v.contactInfo")["PJN_Country__c"]) {
            const getUserCountryAction = component.get("c.getUserCountry");
            getUserCountryAction.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    component.set("v.defaultCountry", response.getReturnValue());
                }
            });
            $A.enqueueAction(getUserCountryAction);
        } else {
            component.set("v.defaultCountry", component.get("v.contactInfo")["PJN_Country__c"]);
        }

        const getAccountRecTypesAction = component.get("c.getAccountCreateRecordTypes");
        getAccountRecTypesAction.setParams({
            isPersonSearch: component.get("v.isPersonSearch")
        });

        getAccountRecTypesAction.setCallback(this, function(response) {
            const recordTypes = response.getReturnValue();
            component.set("v.recordTypeOptions", recordTypes);
            recordTypes.forEach((recType) => {
                switch (recType.developerName) {
                    case "PJN_Patient":
                        component.set("v.patientRecordTypeId", recType.value);
                        break;
                    case "PJN_Physician":
                        component.set("v.PhysicianRecordTypeId", recType.value);
                        break;
                    case "PJN_Staff":
                        component.set("v.PhysicianStaffRecordTypeId", recType.value);
                        break;
                    case "PJN_Caregiver":
                        component.set("v.caregiverRecordTypeId", recType.value);
                        break;
                }
            });
        });

        const getRecTypesAction = component.get("c.getContactInfoRecordTypes");

        getRecTypesAction.setCallback(this, function(response) {
            const recordTypes = response.getReturnValue();
            component.set("v.ciRecTypeOptions", recordTypes);
            const optionsMap = recordTypes.reduce(
                function (accumulator, recType) {
                    accumulator[recType.value] = recType;
                    return accumulator;
                },
                {}
            );
            component.set("v.ciRecTypeOptionsMap", optionsMap);
        });

        const getAccountCreationFieldsAction = component.get("c.getAccountCreationFields");
        getAccountCreationFieldsAction.setCallback(this, function(response) {
            var fieldsetMap = response.getReturnValue();
            var accRecordTypeId = component.get("v.accountRecordTypeId");
            component.set("v.fieldsetMap", fieldsetMap);
            if (accRecordTypeId) {
                component.set("v.fieldset", fieldsetMap[accRecordTypeId]);
                helper.setRelation(component, event, helper);
            }
        });

        const getContactInfoCreationFieldsAction = component.get("c.getContactInfoCreationFields");
        getContactInfoCreationFieldsAction.setCallback(this, function(response) {
            var fieldsetContactInfoMap = response.getReturnValue();
            component.set("v.fieldsetMapContactInfo", fieldsetContactInfoMap);
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(getAccountRecTypesAction);
        $A.enqueueAction(getRecTypesAction);
        $A.enqueueAction(getAccountCreationFieldsAction);
        $A.enqueueAction(getContactInfoCreationFieldsAction);

    },
    setRelation: function(component) {
        var accRecordTypeId = component.get("v.accountRecordTypeId");
        var patientRecordTypeId = component.get("v.patientRecordTypeId");
        var PhysicianRecordTypeId = component.get("v.PhysicianRecordTypeId");
        var caregiverRecordTypeId = component.get("v.caregiverRecordTypeId");
        var PhysicianStaffRecordTypeId = component.get("v.PhysicianStaffRecordTypeId");
        var fieldsetByRecordIdMap = component.get("v.fieldsetMap");
        switch (accRecordTypeId) {
            case patientRecordTypeId:
                component.set("v.relationRecordTypeId", caregiverRecordTypeId);
                component.set("v.relationButtonLabel", "Add Caregiver");
                component.set("v.relationTitle", "Caregiver");
                break;
            case PhysicianRecordTypeId:
                component.set("v.relationRecordTypeId", PhysicianStaffRecordTypeId);
                component.set("v.relationButtonLabel", "Add Staff");
                component.set("v.relationTitle", "Staff");
                break;
        }
        component.set("v.fieldsetRelation", fieldsetByRecordIdMap[component.get("v.relationRecordTypeId")]);
        component.set("v.displayAddRelation", false);
        component.set("v.displayAddContactInfo", false);
    },
    addCIRecord : function(component, event) {
        component.set("v.newRecTypeId", event.getSource().get("v.value"));
        component.set("v.displayAddContactInfo", true);
    },
    editCIRecord : function (component, event) {
        const index = event.getParam("index");
        component.set("v.currentContactInfoIndex", index);
        component.set("v.displayAddContactInfo", true);
    },
    removeCIRecord : function(component, event) {
        const newContactInfoList = component.get("v.newContactInfoList");
        const indexToRemove = event.getParam("index");
        newContactInfoList.splice(indexToRemove, 1);
        component.set("v.newContactInfoList", newContactInfoList);
    },
    setAccountFieldSet: function (component, event, helper) {
        var accRecordTypeId = component.get("v.accountRecordTypeId");
        var fieldsetMap = component.get("v.fieldsetMap");
        if (accRecordTypeId && fieldsetMap && fieldsetMap[accRecordTypeId]) {
            // This patch is to avoid rendering issues from Lightning when moving from a list of fields
            // with higher number of fields to one with less number of fields. We need to add them as hidden
            var oldFieldsetList = component.get("v.fieldset");
            var newFieldsetList = fieldsetMap[accRecordTypeId];
            if (oldFieldsetList && oldFieldsetList.length > newFieldsetList.length) {
                var i = newFieldsetList.length;
                while (i < oldFieldsetList.length) {
                    newFieldsetList.push({"PJN_Field_API_Name__c":"RecordTypeId", "hide":"true"});
                    i++;
                }
            }
            // We should be doing just this: component.set('v.fieldset', component.get('v.fieldsetMap')[component.get('v.accountRecordTypeId')]);
            // End of workaround
            component.set("v.fieldset", newFieldsetList);
            helper.setRelation(component, event, helper);
        }
    },
    submit: function (component, event, helper) {
        component.set("v.isLoading", true);
        var missingData = helper.validateData(component);
        if (!missingData) {
            // Get Account data
            var accountForm = component.find("accountFormId");
            var account = accountForm.getSubmittedData();

            const action = component.get("c.createAccount");
            action.setParams({
                account: JSON.stringify(account),
                contactInfoString: JSON.stringify(component.get("v.newContactInfoList")),
                caseId: component.get("v.case.Id")
            });

            action.setCallback(this, function(response) {
                var resp = response.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");

                if (response.getState() === "ERROR") {
                    let message = "Unknown Error";
                    let errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message = errors[0].message;
                    }

                    toastEvent.setParams({
                        title: "Error",
                        message,
                        type: "error"
                    });
                    toastEvent.fire();

                } else {

                    if (resp != null && component.get("v.case.Id") !== null) {
                        component.set("v.case", resp.case);
                    }

                    toastEvent.setParams({
                        title: "Success",
                        message: "Account successfully created.",
                        type: "success"
                    });
                    toastEvent.fire();

                    // Open "Choose enrollment address" screen when new physician is created
                    if (component.get("v.case.Id") !== null &&
                        account.RecordTypeId === component.get("v.PhysicianRecordTypeId") &&
                        resp != null && resp.PJN_Physician__c !== null) {

                        component.set("v.addressesAccount", {Id: resp.PJN_Physician__c} );
                    }

                    component.set("v.showNewAccountForm", false);
                    component.set("v.account", {});
                    component.set("v.contactInfo", {});

                    if (component.get("v.case.Id") === null && resp && resp.AccountId) {
                        this.showAccount(component, resp.AccountId);
                    }

                    $A.get("e.c:PJN_AccountSearchRefreshCase").fire();
                }
                component.set("v.isLoading", false);
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.isLoading", false);
        }
    },
    showAccount: function(component, acctId) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId": acctId,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).catch(function(error) {
            component.find("notifLib")
                .showToast({
                    variant: "error",
                    title: $A.get("$Label.c.PJN_Error_Title_Notification"),
                    message: error
                });
        });
    },
    validateData: function(component) {
        var missingData = false;

        // Validate New Account Form
        var accountForm = component.find("accountFormId");
        missingData = accountForm.validateData();

        //Validation of contact info is done in the form
        if (missingData) {
            // Fire error
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Error",
                message: "Please, fill in all required fields",
                type: "error"
            });
            toastEvent.fire();
        }
        return missingData;
    },
    addContactInfoRecord: function(component, event) {
        var newContactInfoList = component.get("v.newContactInfoList");
        newContactInfoList.push(event.getParam("newContactInfo"));
        component.set("v.newContactInfoList", newContactInfoList);
        component.set("v.displayAddContactInfo", false);

    },
    handleSubmittedRecord: function(component, event) {
        const params = event.getParams();
        const newContactInfoList = component.get("v.newContactInfoList");
        if (newContactInfoList.length > params.index) {
            newContactInfoList[params.index] = params.fields;
        } else {
            newContactInfoList.push(params.fields);
        }
        component.set("v.newContactInfoList", newContactInfoList);
        component.set("v.displayAddContactInfo", false);
        component.set("v.currentContactInfoIndex", newContactInfoList.length);
    }
});