({
    init : function(component, event, helper) {
        helper.getData(component, event, helper);
    },
    getData : function(component, event, helper) {
        var activeComponent = component.get("v.activeComponent");
        var carePlanId = component.get("v.carePlanId");
        var action = component.get("c.getRecords");
        action.setParams({
            "componentSettingId": activeComponent.Id,
            "carePlanId": carePlanId
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var data = response.getReturnValue().data;
                    var columns = response.getReturnValue().columns;
                    component.set("v.data", data);
                    component.set("v.columns", columns);
                    component.set("v.title", activeComponent.PJN_Section_Title__c);
                }
            );
        });
        $A.enqueueAction(action);
    },
    handleRowAction : function(component, event, helper) {
        var action = event.getParam("action");
        var row = event.getParam("row");
        var rows = component.get("v.data");
        var rowIndex = rows.findIndex( currentRow => currentRow.Id === row.Id);
        var selectedRecord = rows[rowIndex];
        switch (action.name) {
            case "edit":
                helper.editAction(component, event, helper, selectedRecord.Id);
                break;
            case "delete":
                helper.deleteAction(component, event, helper, selectedRecord);
                break;
        }
    },
    editAction : function(component, event, helper, recordId) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": $A.get("$Label.c.PJN_Load_Record_Message"),
            "type": "success",
            "duration": "2000"
        });
        toastEvent.fire();
        var enrollmentFormRefreshEvent = $A.get("e.c:PJN_EnrollmentWizardRecordFormRefreshEvent");
        enrollmentFormRefreshEvent.setParams({
            "recordId" : recordId
        });
        enrollmentFormRefreshEvent.fire();
    },
    deleteAction : function(component, event, helper, record) {
        var confirmed = confirm($A.get("$Label.c.PJN_Delete_Confirmation_Message"));

        if (confirmed) {
            var action = component.get("c.deleteRecord");
            action.setParams({
                "record": record
            });
            action.setCallback(this, function(response) {
                var toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": $A.get("$Label.c.PJN_Deletion_Record_Success_Message"),
                            "type": "success"
                        });
                        toastEvent.fire();

                        var enrollmentStepEvent = component.getEvent("enrollmenWizardStepEvent");
                        enrollmentStepEvent.setParams({
                            "refresh" : true
                        });
                        enrollmentStepEvent.fire();
                    }
                );
            });
            $A.enqueueAction(action);
        }

    }
});