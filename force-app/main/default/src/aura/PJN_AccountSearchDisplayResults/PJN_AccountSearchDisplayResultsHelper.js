({
    initialize : function(component) {
        const action = component.get("c.getFieldUpdateability");
        action.setStorable();
        action.setParams({ objectName: "Case" });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                response => component.set(
                    "v.fieldUpdateability",
                    response.getReturnValue()
                )
            );
        });
        $A.enqueueAction(action);

        const caseFieldsAction = component.get("c.getConfiguredCaseFieldMapByAccountRecType");
        caseFieldsAction.setStorable();
        caseFieldsAction.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                response => component.set( "v.caseAcctLookupFields", response.getReturnValue() )
            );
        });
        $A.enqueueAction(caseFieldsAction);

        const createableRecTypesAction = component.get("c.getCreatableRecordTypes");
        createableRecTypesAction.setStorable();
        createableRecTypesAction.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                response => component.set("v.creatableAccountRecordTypeIds", response.getReturnValue())
            );
        });
        $A.enqueueAction(createableRecTypesAction);

        this.setColumns(component);
    },

    getRowActions: function (component, row, doneCallback) {
        const actions = [];
        if (row.acctId) {
            actions.push({
                label: "Show " + row["AccountRecordType.Name"] + " Details",
                iconName: "utility:description",
                name: "show_details"
            });
        } else {
            if(!component.get("v.case")) {
                actions.push({
                    label: "Download Network Result",
                    iconName: "utility:download",
                    name: "download"
                });
            }
        }
        if(component.get("v.case")) {
            const fieldUpdateability = component.get("v.fieldUpdateability");
            const acctRecTypeDevName = row["AccountRecordType.DeveloperName"];
            const caseAcctLookupFields = component.get("v.caseAcctLookupFields");
            const fieldToUpdate = caseAcctLookupFields[acctRecTypeDevName];

            if (fieldUpdateability[fieldToUpdate]) {
                actions.push({
                    label: "Select " + row["AccountRecordType.Name"],
                    iconName: "utility:add",
                    name: "select_account"
                });
            }
        }

        doneCallback(actions);
    },

    handleAction : function(component, event) {
        const action = event.getParam("action");

        switch (action.name) {
            case "show_details":
                this.showDetails(component, event);
                break;
            case "download":
                this.selectAccount(component, event);
                break;
            case "select_account":
                this.selectAccount(component, event);
                break;
        }
    },

    showDetails: function(component, event) {
        const row = event.getParam("row");
        this.showAccount(component, row.acctId);
    },

    showAccount: function(component, acctId) {
        var navigationEvent = $A.get("e.force:navigateToSObject");
        navigationEvent.setParams({
            "recordId": acctId,
            "slideDevName": "detail"
        });
        navigationEvent.fire();
    },

    selectAccount: function(component, event) {
        component.set("v.searching", true);
        const selectAction = component.get("c.selectAccount");

        const row = _.cloneDeep(event.getParam("row")); //Using lodash library for this
        const resultsByAccountId = component.get("v.resultsByAccountId");

        let acctId = (row.acctId != null && row.acctId != '') ? row.acctId : row.acctExtId;

        const selectedResult = resultsByAccountId[acctId];
        // the next values cause deserialization issues if selected
        // so just remove them from the object in case the result is selected
        Object.keys(selectedResult.accountDetail).forEach(field => {
            if (Array.isArray(selectedResult.accountDetail[field])) {
                delete selectedResult.accountDetail[field];
            }
        })
        delete selectedResult.singleResultByField;
        console.log("selectedResult", selectedResult);
        selectAction.setParams({
            currentCase: component.get("v.case"),
            originalResult: JSON.stringify(selectedResult)
        });

        selectAction.setCallback(this, function(response, errorMsg) {
            let state = response.getState();
            let noticeParams = {};
            let successful = false;

            if (state === "SUCCESS") {
                let message = "Account Downloaded";
                if(component.get("v.case")) {
                    component.set("v.case", response.getReturnValue());
                    message = "Account Selected";
                }
                noticeParams = {
                    variant: "success",
                    title: state,
                    message
                };

                successful = true;
            } else if (state === "ERROR") {
                let message = "Error downloading account";
                if (component.get("v.case")) {
                    message = "Error selecting account";
                }
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        message += ": " + errors[0].message;
                    }
                }
                noticeParams = {
                    variant: "error",
                    title: state,
                    message
                };
            } else {
                let message = "Unable to download account: ";
                if (component.get("v.case")) {
                    message = "Unable to select account: ";
                }
                noticeParams = {
                    variant: "error",
                    title: state,
                    message : message + errorMsg
                };
            }
            let showNotification = !successful;

            if(successful) {
                if(component.get("v.isPersonSearch")) {
                    switch(row["AccountRecordType.DeveloperName"]) {
                        case "PJN_Physician":
                            this.displayContactInformation(component, {Id: response.getReturnValue().PJN_Physician__c});
                            break;
                        case "PJN_Patient":
                            this.displayCarePlans(component, component.get("v.resultsByAccountId")[acctId].accountDetail);
                            break;
                        default:
                            showNotification = true;
                    }
                }
            }
            component.set("v.searching", false);
            if(showNotification) {
                component.find("notifLib").showToast(noticeParams);
            }
            if(!component.get("v.case")) {
                //server will return a case with the new Account Id set to AccountId
                const retVal = response.getReturnValue();
                if (retVal) {
                    this.showAccount(component, retVal.AccountId);
                }
            }
        });
        $A.enqueueAction(selectAction);
    },

    displayContactInformation: function(component, account) {
        const mainCase = component.get("v.case");
        if (!mainCase) {
            return;
        }
        const needsCarePlan = mainCase.ParentId ? mainCase.ParentId.trim().length === 0 : true;

        // Only display modal when the search wasn't from a care plan and the case doesn't already have a care plan specified
        if(mainCase.RecordType.DeveloperName != "CarePlan" && needsCarePlan) {
            component.set("v.addressesAccount", account);
        }
    },

    displayCarePlans: function(component, account) {
        const mainCase = component.get("v.case");

        // Only display care plan selector when the search wasn't from a care plan
        if(mainCase.RecordType.DeveloperName != "CarePlan") {
            component.set("v.carePlansAccount", account);
        }
    },

    showForm: function(component, showForm) {
        component.set("v.showNewAccountForm", showForm);
    },

    assembleResults: function(component) {
        const searchedAcct = component.get("v.account");
        const searchableAccountRecTypeIds = component.get("v.creatableAccountRecordTypeIds");

        // determine whether the searched record type should allow new account creation.
        // makes no sense to show the new account button if user isn't allowed to create
        let canCreate = false;
        component.set("v.canCreateNewAccount", false);
        if (searchedAcct.RecordTypeId) {
            if(searchableAccountRecTypeIds.includes(searchedAcct.RecordTypeId)) {
                canCreate = true;
            }
        } else {
            // when there is no record type id then the all was searched, allow new account
            canCreate = true;
        }
        component.set("v.canCreateNewAccount", canCreate);

        this.setColumns(component);
        let results = component.get("v.results");
        if (!results) {
            results = [];
        }
        const displayableResults = results.map(
            result => result.singleResultByField
        );

        const resultsByAccountId = {};
        results.forEach(
            result => {
                let acctId = (result.accountDetail.Id != null && result.accountDetail.Id != '') ? result.accountDetail.Id : result.accountExternalId;
                resultsByAccountId[acctId] = result;
            }
        );
        component.set("v.displayableResults", displayableResults);
        component.set("v.resultsByAccountId", resultsByAccountId);
    },

    setColumns: function(component) {
        const getColumsAction = component.get("c.getFields");
        const rowActions = this.getRowActions.bind(this, component);
        const fieldSet = component.get("v.isPersonSearch") ? "Person_Search_Results" : "Business_Search_Results";

        getColumsAction.setParams({
            fieldSetName : fieldSet,
            recordTypeId : component.get("v.account.RecordTypeId")
        });

        getColumsAction.setCallback(this, function(res) {
            const columns = res.getReturnValue().map(function(value) {
                value.type = "text";
                value.fieldName = value.objectFieldName;
                return value;
            });

            columns.push({ type: "action", typeAttributes: { rowActions } });

            component.set("v.columns", columns);
        });

        $A.enqueueAction(getColumsAction);
    }
});