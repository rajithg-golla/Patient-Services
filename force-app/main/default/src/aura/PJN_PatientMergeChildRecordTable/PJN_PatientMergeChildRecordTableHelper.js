({
    setSelectedRecords : function(component, event, helper) {
        var selectedAccountId = component.get("v.selectedAccountId");
        var masterCarePlanId = component.get("v.masterCarePlanId");
        var selectedRecords = component.get("v.selectedChildrenRecordMap");
        var parentObjectName = component.get("v.parentObjectName");
        var childRecord = component.get("v.childRecord");
        var selectedContactInfoList = selectedRecords[childRecord.childRecordName];
        // Pre-select records linked to master account
        if (!selectedContactInfoList && selectedAccountId) {
            selectedContactInfoList = [];
            var selectedContactInfoListRecords = [];
            childRecord.recordList.forEach((record) => {
                var accId = record.PJN_Account__c ? record.PJN_Account__c : record.AccountId;
                if (accId == selectedAccountId) {
                    selectedContactInfoListRecords.push(record);
                    selectedContactInfoList.push(record.Id);
                }
            });
            // Send pre-selected records to wizard
            var selectChildRecordEvent = component.getEvent("selectChildRecordEvent");
            selectChildRecordEvent.setParams({
                masterCarePlanId: masterCarePlanId,
                objectName: childRecord.childRecordName,
                selectedRecordList: selectedContactInfoListRecords,
                parentObjectName: parentObjectName
            });
            selectChildRecordEvent.fire();
        }
        var dataTableComponent = component.find("datatable");
        dataTableComponent.set("v.selectedRows", selectedContactInfoList);
    },
    handleRowSelection : function(component, event, helper) {
        var parentObjectName = component.get("v.parentObjectName");
        var childRecord = component.get("v.childRecord");
        var masterCarePlanId = component.get("v.masterCarePlanId");
        var selectedRowList = event.getParam("selectedRows");
        var selectChildRecordEvent = component.getEvent("selectChildRecordEvent");
        selectChildRecordEvent.setParams({
            masterCarePlanId: masterCarePlanId,
            objectName: childRecord.childRecordName,
            selectedRecordList: selectedRowList,
            parentObjectName: parentObjectName
        });
        selectChildRecordEvent.fire();
    },
    handleAction : function(component, event, helper) {
        var action = event.getParam("action");
        var row = event.getParam("row");
        var data = component.get("v.childRecord.recordList");
        if (action.name === "primary"){
            var dataWithUpdatedPrimaries = helper.setPrimaries(row, data);
            component.set("v.childRecord.recordList", dataWithUpdatedPrimaries);

            var primaryIdList = helper.getPrimaries(dataWithUpdatedPrimaries);

            var selectPrimaryEvent = component.getEvent("selectPrimaryContactInfoEvent");
            selectPrimaryEvent.setParams({
                primaryIdList: primaryIdList
            });
            selectPrimaryEvent.fire();
        } else if (action.name === "view"){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": row.Id
            });
            navEvt.fire();
        }
    },
    setPrimaries : function(actionRow, data){
        // Don't modify directly data, best practice
        var dataCopy = JSON.parse(JSON.stringify(data));
        // If clicked, the new value is the opposite
        var rowValue = !actionRow.PJN_Primary__c;
        dataCopy.forEach((row) => {
            if (row.Id === actionRow.Id){
                row.PJN_Primary__c = rowValue;
                return;
            }
            // if a new primary is selected, the other ones have to be set to false
            if (rowValue && row.PJN_Record_Type_Name__c === actionRow.PJN_Record_Type_Name__c){
                row.PJN_Primary__c = false;
            }
        });
        return dataCopy;
    },
    getPrimaries : function(data) {
        var primaryIdList = [];
        data.forEach((row) => {
            if (row.PJN_Primary__c) {
                primaryIdList.push(row.Id);
            }
        });
        return primaryIdList;
    },
});