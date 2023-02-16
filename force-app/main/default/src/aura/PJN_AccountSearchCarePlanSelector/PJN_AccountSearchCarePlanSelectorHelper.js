({
    getPlans : function(component) {
        if (!component.get("v.account.Id") || !component.get("v.case.Id")) {
            return;
        }
        const planAction = component.get("c.getCarePlans");
        planAction.setParams({
            accountId: component.get("v.account.Id"),
            caseId:    component.get("v.case.Id")
        });

        $A.enqueueAction(planAction);

        planAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;

            switch(response.getState()) {
                case "SUCCESS":
                    let plans = response.getReturnValue();
                    if(plans && plans.carePlanWrapperList.length) {
                        component.set("v.plansWrapper", plans.carePlanWrapperList);
                        component.set("v.fieldsList", plans.fieldList);
                        component.set("v.fields", plans.fieldList.join(","));
                        component.set("v.fieldsLabels", plans.fieldLabels);
                        var colSize = Math.floor(11/plans.fieldLabels.length);
                        component.set("v.columnSize", colSize);
                        component.set("v.show", true);
                    } else {
                        let noticeParams = {
                            variant: "success",
                            title: response.getState(),
                            message: $A.get("$Label.c.PJN_Patient_selected_success_message")
                        };
                        component.find("notifLib").showToast(noticeParams);
                        this.finished(component);
                    }
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: $A.get("$Label.c.PJN_Retrieve_care_plans_error_message")
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: $A.get("$Label.c.PJN_Retrieve_care_plans_error_message") + ": " + errorMsg
                    };
            }

            if(noticeParams) {
                component.find("notifLib").showToast(noticeParams);
            }
        });

    },

    setCarePlan : function (component, recordId) {
        const planAction = component.get("c.setPatientCarePlan");
        planAction.setParams({
            caseId: component.get("v.case.Id"),
            planId   : recordId
        });

        $A.enqueueAction(planAction);

        planAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;
            let success = false;
            const retVal= response.getReturnValue();

            switch(response.getState()) {
                case "SUCCESS":
                    if(retVal) {
                        component.set("v.case", retVal);
                        success = true;
                        noticeParams = {
                            variant: "success",
                            title: response.getState(),
                            message: $A.get("$Label.c.PJN_Care_Plan_Selected_Success_Message")
                        };
                    } else {
                        noticeParams = {
                            variant: "error",
                            title: response.getState(),
                            message: $A.get("$Label.c.PJN_Care_Plan_Selection_Error_Message")
                        };
                    }
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title: response.getState(),
                        message: $A.get("$Label.c.PJN_Care_Plan_Selection_Error_Message")
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title: response.getState(),
                        message: $A.get("$Label.c.PJN_Care_Plan_Selection_Error_Message") + ": " + errorMsg
                    };
            }

            component.find("notifLib").showToast(noticeParams);

            if (success) {
                this.finished(component);
            }
        });
    },

    finished : function(component) {
        $A.get("e.c:PJN_AccountSearchRefreshCase").fire();
        component.set("v.account", null);
    }

});