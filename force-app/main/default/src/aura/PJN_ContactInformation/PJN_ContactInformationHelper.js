({
    init : function(component, event, helper) {
        helper.getContactInfo(component, event, helper);
        helper.getIdType(component, event, helper);
    },
    getContactInfo : function(component, event, helper) {
        component.set("v.isLoading", true);
        var recordId = component.get("v.recordId");
        var action = component.get("c.getContactInformation");
        action.setParams({
            "parentId": recordId
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var contactInformation = response.getReturnValue();
                    component.set("v.data", contactInformation.data);
                    component.set("v.numberOfRecords", contactInformation.data.length);

                    const actions = contactInformation.columns.filter(column => column.type === "action")[0].typeAttributes.rowActions;
                    component.set("v.actions", actions);

                    const rowActions = helper.getRowActions.bind(this, component);
                    const columns = contactInformation.columns.filter(column => column.type !== "action");
                    columns.push({ type: "action", typeAttributes: { rowActions } });
                    component.set("v.columns", columns);

                    component.set("v.isLoading", false);
                }
            );
        });
        $A.enqueueAction(action);
    },
    getIdType : function(component, event, helper) {
        component.set("v.isLoading", true);
        var recordId = component.get("v.recordId");
        var action = component.get("c.getParentType");
        action.setParams({
            "parentId": recordId
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var idType = response.getReturnValue();
                    var isAccount = idType === "Account";
                    component.set("v.isAccount", isAccount);
                    var isCarePlan = idType === "CarePlan";
                    component.set("v.isCarePlan", isCarePlan);
                    component.set("v.isLoading", false);
                }
            );
        });
        $A.enqueueAction(action);
    },
    new : function(component, event, helper) {
        var isAccount = component.get("v.isAccount");
        var isCarePlan = component.get("v.isCarePlan");
        var defaultFieldValues = {};
        if(isAccount) {
            var recordId = component.get("v.recordId");
            defaultFieldValues = {
                "PJN_Account__c": recordId
            };
        } else if(isCarePlan) {
            var carePlan = component.get("v.carePlan");
            defaultFieldValues = {
                "PJN_Account__c": carePlan.AccountId
            };
        }
        component.set("v.defaultFieldValues", defaultFieldValues);
        component.set("v.showNew", true);
    },
    viewAll : function(component, event, helper) {
        var isAccount = component.get("v.isAccount");
        var isCarePlan = component.get("v.isCarePlan");
        var recordId;
        if(isAccount) {
            recordId = component.get("v.recordId");
        } else if(isCarePlan) {
            var carePlan = component.get("v.carePlan");
            recordId = carePlan.AccountId;
        }
        var pageReference = {
            "type": "standard__recordRelationshipPage",
            "attributes": {
                "recordId": recordId,
                "objectApiName": (isCarePlan ? "Case" : "Account"),
                "relationshipApiName": "PJN_Contact_Information__r",
                "actionName": "view"
            }
        };
        var navService = component.find("navService");
        navService.navigate(pageReference);
    },
    getRowActions: function (component, row, doneCallback) {
        const actions = component.get("v.actions");

        let dynamicActions = [];
        let optActions = actions.filter(action => action.name === "optin" || action.name === "optout");
        if(optActions.length) {
            let optInAction = actions.filter(action => action.name === "optin")[0];
            let optOutAction = actions.filter(action => action.name === "optout")[0];
            if(row["Consent_Status"] === "Opt In") {
                optInAction["disabled"] = true;
                optOutAction["disabled"] = false;
            } else {
                optInAction["disabled"] = false;
                optOutAction["disabled"] = true;
            }
            dynamicActions.push(optInAction);
            dynamicActions.push(optOutAction);
        }

        let otherActions = actions.filter(action => action.name !== "optin" && action.name !== "optout");
        dynamicActions = dynamicActions.concat(otherActions);

        doneCallback(dynamicActions);
    },
    handleRowAction: function(component, event, helper) {
        var action = event.getParam("action");
        var row = event.getParam("row");
        var rows = component.get("v.data");
        var rowIndex = rows.findIndex( currentRow => currentRow.Id === row.Id);
        var selectedRecord = rows[rowIndex];

        switch (action.name) {
            case "showdetails":
                helper.showDetails(component, event, helper, selectedRecord);
                break;
            case "edit":
                helper.edit(component, event, helper, selectedRecord);
                break;
            case "delete":
                helper.deleteRecord(component, event, helper, selectedRecord);
                break;
            case "optin":
                helper.optIn(component, event, helper, selectedRecord);
                break;
            case "optout":
                helper.optOut(component, event, helper, selectedRecord);
                break;
        }
    },
    showDetails : function(component, event, helper, selectedRecord) {
        var contactInformationDetailsEvent = $A.get("e.force:navigateToSObject");
        contactInformationDetailsEvent.setParams({
            "recordId": selectedRecord.Id,
            "slideDevName": "detail"
        });
        contactInformationDetailsEvent.fire();
    },
    edit : function(component, event, helper, selectedRecord) {
        var contactInformationEditEvent = $A.get("e.force:editRecord");
        contactInformationEditEvent.setParams({
            "recordId": selectedRecord.Id
        });
        contactInformationEditEvent.fire();
    },
    deleteRecord : function(component, event, helper, selectedRecord) {
        var confirmed = confirm($A.get("$Label.c.PJN_Contact_Information_Delete_Confirmation_Message").replace("{0}", selectedRecord.PJN_Value__c));
        if(confirmed) {
            var action = component.get("c.deleteContactInformation");
            action.setParams({
                "contactInformationId": selectedRecord.Id
            });
            action.setCallback(this, function(response) {
                var toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        var successToastEvent = $A.get("e.force:showToast");
                        successToastEvent.setParams({
                            title: "Success",
                            type: "success",
                            message: $A.get("$Label.c.PJN_Contact_Information_Delete_Success_Message").replace("{0}", selectedRecord.PJN_Value__c)
                        });
                        successToastEvent.fire();
                        $A.get("e.force:refreshView").fire();
                    }
                );
            });
            $A.enqueueAction(action);
        }
    },
    optIn : function(component, event, helper, selectedRecord) {
        var carePlan = component.get("v.carePlan");
        var action = component.get("c.optInContactInformation");
        action.setParams({
            "contactInformationId": selectedRecord.Id,
            "programDeveloperName": carePlan.PJN_Program_DeveloperName__c
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var successToastEvent = $A.get("e.force:showToast");
                    successToastEvent.setParams({
                        title: "Success",
                        type: "success",
                        message: $A.get("$Label.c.PJN_Contact_Information_Opt_In_Success_Message").replace("{0}", selectedRecord.PJN_Value__c)
                    });
                    successToastEvent.fire();
                    $A.get("e.force:refreshView").fire();
                }
            );
        });
        $A.enqueueAction(action);
    },
    optOut : function(component, event, helper, selectedRecord) {
        var carePlan = component.get("v.carePlan");
        var action = component.get("c.optOutContactInformation");
        action.setParams({
            "contactInformationId": selectedRecord.Id,
            "programDeveloperName": carePlan.PJN_Program_DeveloperName__c
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var successToastEvent = $A.get("e.force:showToast");
                    successToastEvent.setParams({
                        title: "Success",
                        type: "success",
                        message: $A.get("$Label.c.PJN_Contact_Information_Opt_Out_Success_Message").replace("{0}", selectedRecord.PJN_Value__c)
                    });
                    successToastEvent.fire();
                    $A.get("e.force:refreshView").fire();
                }
            );
        });
        $A.enqueueAction(action);
    }
});