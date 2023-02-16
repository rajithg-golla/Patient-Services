({
    initializeColumns : function(component) {
        component.set("v.searchPerformed", false);
        var getUserCountryAction = component.get("c.getUserCountry");
        getUserCountryAction.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var country = response.getReturnValue();
                component.set("v.defaultCountry", country);
            }
            $A.enqueueAction(getColumnsAction);
        });

        const getColumnsAction = component.get("c.getFields");

        getColumnsAction.setParams({
            fieldSetName : component.get("v.fieldSetName"),
            recordTypeId : component.get("v.account.RecordTypeId")
        });

        getColumnsAction.setCallback(this, function(res) {
            const acctFields = [];
            const ciFields = [];
            res.getReturnValue().forEach( field => {
                if (field.objectName === "Account") {
                    acctFields.push(field);
                } else if (field.objectName === "PJN_Contact_Information__c") {
                    if (field.fieldName === "PJN_Country__c") {
                        field.defaultValue = component.get("v.defaultCountry");
                    }
                    if (field.fieldName === "PJN_Phone__c") {
                        field.defaultValue = component.get("v.phone");
                    }
                    ciFields.push(field);
                }
            });
            component.set("v.accountSearchFieldsArray", acctFields);
            component.set("v.contactInfoSearchFieldsArray", ciFields);

            console.log("incoming call", component.get("v.incomingCall"))
            if (component.get("v.incomingCall")){
                component.set("v.incomingCall", false);
                this.submitForm(component, true);
            }
        });

        $A.enqueueAction(getUserCountryAction);
    },

    recordTypeUpdate : function(component) {
        const selector = component.find("selector");
        const types = selector.getSelectedRecordTypes();
        const rtId = (types.length === 1) ? types[0] : "";

        component.set("v.account.RecordTypeId", rtId);
        component.set("v.isPersonSearch", selector.isPersonAccountSelected());
        component.set(
            "v.fieldSetName",
            selector.isPersonAccountSelected()
                ? "Person_Search_Form"
                : "Business_Search_Form"
        );
        this.initializeColumns(component);
    },

    submitForm : function(component, phoneSearch) {
        component.set("v.searching", true);
        const accountInputs = component.find("accountForm").getInputs();
        let ciInputs;
        if (phoneSearch) {
            ciInputs = {
                "PJN_Phone__c": component.get("v.phone"),
                "PJN_Country__c": component.get("v.defaultCountry")
            };
        } else {
            ciInputs = component.find("ciForm").getInputs();
        }

        const aLength = Object.keys(accountInputs).length;
        const cLength = Object.keys(ciInputs).length;

        if (aLength + cLength < 2 && !phoneSearch) {
            component.set("v.searching", false);
            component.find("notifLib").showToast({
                variant: "warning",
                message: $A.get("$Label.c.PJN_Account_Search_No_Search_Terms_Message")
            });
            component.set("v.searching", false);
        } else {
            component.set("v.account", accountInputs);
            component.set("v.contactInfo", ciInputs);
            component.set("v.searchPerformed", true);
            component.set("v.results", []);

            const selectedRecTypeIds = component.find("selector").getSelectedRecordTypes();
            if (selectedRecTypeIds && selectedRecTypeIds.length === 1) {
                accountInputs.RecordTypeId = selectedRecTypeIds[0];
            }

            const searchRequestObject = {
                account:  accountInputs,
                contactInfo: ciInputs,
                isPersonSearch: component.find("selector").isPersonAccountSelected()
            };

            const searchRequest = JSON.stringify(searchRequestObject);
            const action = component.get("c.search");
            action.setParams({ searchRequest });

            // set the callback
            action.setCallback(this, function(response) {
                component.set("v.searching", false);

                let noticeParams;
                switch(response.getState()) {
                    case "SUCCESS":
                        component.set("v.searchPerformed", true);
                        component.set("v.results", response.getReturnValue());
                        break;
                    case "ERROR":
                        let errors = response.getError();
                        let error = "Unknown Error";
                        if (errors && Array.isArray(errors) && errors.length > 0) {
                            if (!errors[0].message.includes("internal server")) {
                                error = errors[0].message;
                            }
                        }
                        noticeParams = {
                            variant: "error",
                            title:  response.getState(),
                            message: error,
                            mode: "sticky",
                        };
                        break;
                    default:
                        noticeParams = {
                            variant: "error",
                            title:  response.getState(),
                            message: "Unable to perform search. Please verify your internet connection and try again."
                        };
                }

                if(noticeParams) {
                    component.find("notifLib").showToast(noticeParams);
                }
            });

            $A.enqueueAction(action);
        }
    },

    clearForm : function (component) {
        component.find("accountForm").clear();
        component.find("ciForm").clear();
    },

});