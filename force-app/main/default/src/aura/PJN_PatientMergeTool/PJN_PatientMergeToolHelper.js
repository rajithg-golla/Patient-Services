({
    handleInit : function(component, event, helper) {
        helper.resetAttributes(component, event, helper);

        var selectedRecord = component.get("v.selectedRecord");

        var actionGetAccounts = component.get("c.getAccounts");
        actionGetAccounts.setParams({
            accountIdList: [selectedRecord.PJN_Patient_1__c, selectedRecord.PJN_Patient_2__c]
        });
        actionGetAccounts.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            component.set("v.accountList", resp.accountList);
            component.set("v.accountFieldList", resp.fieldList);
        });

        var actionGetCarePlans = component.get("c.getCarePlanRecords");
        actionGetCarePlans.setParams({
            accountIdList: [selectedRecord.PJN_Patient_1__c, selectedRecord.PJN_Patient_2__c]
        });
        actionGetCarePlans.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            component.set("v.carePlanWrapList", resp);
            component.set("v.allCarePlanList", resp.recordList);
            component.set("v.carePlanList", resp.recordList);
            component.set("v.carePlanFieldList", resp.fieldList);
            component.set("v.carePlanCardFieldList", resp.cardFieldList);

            var carePlanIds = [];
            resp.recordList.forEach((carePlan) => {
                carePlanIds.push(carePlan.Id);
            });
            component.set("v.carePlanIdsList", carePlanIds);

            var actionGetChildRecords = component.get("c.getChildRecords");
            actionGetChildRecords.setParams({
                carePlanIdsList: component.get("v.carePlanIdsList")
            });
            actionGetChildRecords.setCallback(this, function(response) {
                var resp = response.getReturnValue();
                component.set("v.childRecordList", resp);
            });
            $A.enqueueAction(actionGetChildRecords);
        });

        var actionGetContactInfo = component.get("c.getContactInformationRecords");
        actionGetContactInfo.setParams({
            accountIdList: [selectedRecord.PJN_Patient_1__c, selectedRecord.PJN_Patient_2__c]
        });
        actionGetContactInfo.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            component.set("v.contactInfoList", resp);
        });

        $A.enqueueAction(actionGetAccounts);
        $A.enqueueAction(actionGetCarePlans);
        $A.enqueueAction(actionGetContactInfo);
    },
    resetAttributes : function(component, event, helper) {
        component.set("v.selectedAccountId", null);
        component.set("v.selectedCarePlan", null);
        component.set("v.selectedChildrenRecordMap", {});
        component.set("v.primaryContactInfoIdList", []);
        component.set("v.currentStep", 1);
    },
    showModal : function(component, event, helper) {
        component.set("v.showModal", true);
    },
    hideModal : function(component, event, helper) {
        var confirmed = confirm($A.get("$Label.c.PJN_Confirm_Exit_Message"));
        if (confirmed) {
            component.set("v.showModal", false);
        }
    },
    handleSelectAccount : function(component, event, helper) {
        component.set("v.selectedAccountId", event.getParam("selectedId"));
    },
    handleSelectCarePlan : function(component, event, helper) {
        var idList = component.get("v.selectedCarePlanIdlist");
        idList.push(event.getParam("selectedCarePlan").Id);
        component.set("v.selectedCarePlanIdlist", idList);

        component.set("v.selectedCarePlan", event.getParam("selectedCarePlan"));
    },
    handlePrevious: function(component, event, helper) {
        var currentStep = component.get("v.currentStep");
        var firstStep = component.get("v.firstStep");
        if(currentStep < firstStep){
            console.warn("You already reached the first step! Current Step = "+currentStep + " firstStep = "+firstStep);
            return;
        } else if(currentStep == firstStep){
            helper.hideModal(component, event, helper);
            return;
        }
        var nextStep = currentStep-1;
        component.set("v.currentStep", nextStep);
    },
    handleNext: function(component, event, helper) {
        var currentStep = component.get("v.currentStep");
        var lastStep = component.get("v.lastStep");
        if (currentStep > lastStep) {
            console.warn("You already reached the last step!");
            return;
        } else if (currentStep == 2 && component.get("v.carePlanList").length > 1 && Object.keys(component.get("v.mergedCarePlans")).length == 0){
            var confirmed = confirm($A.get("$Label.c.PJN_Patient_Merge_Tool_Confirm_No_Merge"));
            if (!confirmed) {
                return;
            }
        } else if (currentStep == lastStep) {
            component.set("v.isLoading", true);
            helper.merge(component, event, helper);
            return;
        }
        if (!helper.validateData(component, event, helper)) {
            var errorToastEvent = $A.get("e.force:showToast");
            errorToastEvent.setParams({
                title: "Error",
                type: "error",
                message: $A.get("$Label.c.PJN_Patient_Merge_Tool_Select_Record_Error")
            });
            errorToastEvent.fire();
            return;
        }
        var nextStep = currentStep+1;
        component.set("v.currentStep", nextStep);
    },
    validateData: function(component, event, helper) {
        var currentStep = component.get("v.currentStep");
        var selectedAccountId = component.get("v.selectedAccountId");
        var selectedCarePlan = component.get("v.selectedCarePlan");
        if (currentStep == 1 && !selectedAccountId) {
            return false;
        }
        return true;
    },
    handleSelectChildRecord : function(component, event, helper) {
        var masterCarePlanId = event.getParam("masterCarePlanId");
        var sObjectName = event.getParam("objectName");
        var parentObjectName = event.getParam("parentObjectName");
        var selectedRecordList = event.getParam("selectedRecordList");
        if (parentObjectName == "Account") {
            var previousAccountSelectedRecordList = component.get("v.selectedAccountChildrenRecordMap");
            // Set child records
            var selectedRecordIdList = [];
            selectedRecordList.forEach((selectedRecord) => {
                selectedRecordIdList.push(selectedRecord.Id);
            });
            previousAccountSelectedRecordList[sObjectName] = selectedRecordIdList;
            component.set("v.selectedAccountChildrenRecordMap", previousAccountSelectedRecordList);
        } else {
            var previousSelectedRecordList = component.get("v.selectedChildrenRecordMap");
            // Reset selected child records
            if (!sObjectName && !selectedRecordList) {
                delete previousSelectedRecordList[masterCarePlanId];
                return;
            }
            // Set child records
            var selectedChildRecordIdList = [];
            selectedRecordList.forEach((selectedRecord) => {
                selectedChildRecordIdList.push(selectedRecord.Id);
            });
            if (!(masterCarePlanId in previousSelectedRecordList)){
                previousSelectedRecordList[masterCarePlanId] = {};
            }
            previousSelectedRecordList[masterCarePlanId][sObjectName] = selectedChildRecordIdList;
            component.set("v.selectedChildrenRecordMap", previousSelectedRecordList);
        }
    },
    handleSelectPrimary : function(component, event, helper) {
        var primaryIdList = event.getParam("primaryIdList");
        component.set("v.primaryContactInfoIdList", primaryIdList);
    },
    merge: function(component, event, helper) {
        var action = component.get("c.mergeAccounts");
        action.setParams({
            selectedDCRRecordId: component.get("v.selectedRecord").Id,
            selectedPatientId: component.get("v.selectedAccountId"),
            selectedChildrenRecordMapString: JSON.stringify(component.get("v.selectedChildrenRecordMap")),
            selectedAccountChildrenRecordMapString: JSON.stringify(component.get("v.selectedAccountChildrenRecordMap")),
            selectedPrimaryIdList: component.get("v.primaryContactInfoIdList"),
            accountList: component.get("v.accountList"),
            carePlanIdsList: component.get("v.carePlanIdsList"),
            mergedCarePlans: component.get("v.mergedCarePlans")
        });
        action.setCallback(this, function(response) {
            if (response.getState() != "SUCCESS") {
                component.set("v.isLoading", false);
            }
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var accountList = component.get("v.accountList");
                    var successToastEvent = $A.get("e.force:showToast");
                    successToastEvent.setParams({
                        title: "Success",
                        type: "success",
                        message: "Sucessfully merged " + accountList[0].Name + " and " + accountList[1].Name
                    });
                    successToastEvent.fire();

                    component.set("v.isLoading", false);
                    component.set("v.showModal", false);
                    component.getEvent("removeRowEvent").fire();
                }
            );
        });

        $A.enqueueAction(action);
    },
    hideProgressButtons : function(component, event, helper) {
        component.set("v.hideProgressButtons", event.getParam("hide"));
    },
    updateCarePlanList : function(component, event, helper) {
        var carePlanList = event.getParam("carePlanList");
        var carePlanWrapList = component.get("v.carePlanWrapList");
        carePlanWrapList.recordList = carePlanList;
        component.set("v.carePlanWrapList", carePlanWrapList);
        component.set("v.carePlanList", carePlanList);
    },
    setMergedCarePlanIds : function(component, event, helper) {
        var masterCarePlanId = event.getParam("masterCarePlanId");
        var selectedCarePlanIdList = event.getParam("selectedCarePlanIdList");

        var mergedCarePlans = component.get("v.mergedCarePlans");
        mergedCarePlans[masterCarePlanId] = selectedCarePlanIdList;

        component.set("v.mergedCarePlans", mergedCarePlans);
    },
});