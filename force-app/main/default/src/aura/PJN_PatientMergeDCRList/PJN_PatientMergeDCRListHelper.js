({
    init : function(component, event, helper) {
        var action = component.get("c.getDCRRecords");
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    var data = response.getReturnValue().data;
                    var columns = response.getReturnValue().columns;
                    component.set("v.data", data);
                    component.set("v.columns", columns);
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
        component.set("v.selectedRowIndex", rowIndex);
        var selectedRecord = rows[rowIndex];
        switch (action.name) {
            case "merge":
                helper.mergeAction(component, event, helper, selectedRecord);
                break;
            case "reject":
                helper.rejectAction(component, event, helper, selectedRecord, rowIndex);
                break;
        }
    },
    mergeAction : function(component, event, helper, selectedRecord) {
        component.set("v.selectedRecord", selectedRecord);
        component.set("v.showModal", true);
    },
    rejectAction : function(component, event, helper, selectedRecord, rowIndex) {
        var action = component.get("c.rejectMerge");
        action.setParams({
            recordId: selectedRecord.Id,
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
                        message: "Sucessfully rejected merge."
                    });
                    successToastEvent.fire();

                    helper.removeRow(component, event, helper);
                }
            );
        });
        $A.enqueueAction(action);
    },
    removeRow : function(component, event, helper) {
        var allRowsList = component.get("v.data");
        allRowsList.splice(component.get("v.selectedRowIndex"), 1);
        component.set("v.data", allRowsList);
    },
});