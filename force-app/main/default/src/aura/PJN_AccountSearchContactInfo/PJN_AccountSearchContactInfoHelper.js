({
    getAddresses : function(component) {
        const addressAction = component.get("c.getAddresses");
        addressAction.setParams({
            accountId: component.get("v.account.Id")
        });

        $A.enqueueAction(addressAction);

        addressAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;

            switch(response.getState()) {
                case "SUCCESS":
                    component.set("v.addresses", response.getReturnValue());
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve addresses."
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve addresses: " + errorMsg
                    };
            }

            if(noticeParams) {
                component.find("notifLib").showToast(noticeParams);
            }
        });

    },

    getContactMetadata : function(component) {
        // Obtain contact info fields to display
        const fieldsAction = component.get("c.getContactInfoCreationFields");
        $A.enqueueAction(fieldsAction);

        fieldsAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;

            switch(response.getState()) {

                case "SUCCESS":
                    component.set("v.fieldsetContactInfo", response.getReturnValue().PJN_Address);
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve address fields."
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve address fields: " + errorMsg
                    };
            }

            if(noticeParams) {
                component.find("notifLib").showToast(noticeParams);
            }
        });

        // Obtain record type Id for Address
        const rtIdAction = component.get("c.getContactInfoRecordTypeId");
        rtIdAction.setParams({
            developerName: "PJN_Address"
        });
        $A.enqueueAction(rtIdAction);

        rtIdAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;

            switch(response.getState()) {
                case "SUCCESS":
                    component.set("v.addressRtId", response.getReturnValue());
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve address metadata."
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to retrieve address metadata: " + errorMsg
                    };
            }

            if(noticeParams) {
                component.find("notifLib").showToast(noticeParams);
            }
        });
    },

    setPrimaryAddress : function (component, recordId) {
        const addressAction = component.get("c.setPhysicianAddress");
        addressAction.setParams({
            caseId: component.get("v.case.Id"),
            addressId: recordId
        });

        $A.enqueueAction(addressAction);

        addressAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;
            let successful = false;

            switch(response.getState()) {
                case "SUCCESS":
                    if(response.getReturnValue()) {
                        successful = true;
                        noticeParams = {
                            variant: "success",
                            title:  response.getState(),
                            message: "Enrollment address for the Physician has been successfully set."
                        };
                    } else {
                        noticeParams = {
                            variant: "error",
                            title:  response.getState(),
                            message: "Unable to set Physician enrollment address. Please try again."
                        };
                    }
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to set Physician enrollment address."
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title:  response.getState(),
                        message: "Unable to set Physician enrollment address: " + errorMsg
                    };
            }

            component.find("notifLib").showToast(noticeParams);

            if(successful) {
                this.finished(component);
            }
        });
    },

    addPrimaryAddress : function(component, event) {
        // Set the Physician account on the new address
        const address = event.getParams().fields;
        address.PJN_Account__c = component.get("v.account.Id");

        const addressAction = component.get("c.setNewPhysicianAddress");
        addressAction.setParams({
            caseId: component.get("v.case.Id"),
            address: address
        });

        $A.enqueueAction(addressAction);

        addressAction.setCallback(this, function(response, errorMsg) {
            let noticeParams;
            let successful = false;

            switch(response.getState()) {
                case "SUCCESS":
                    if(response.getReturnValue()) {
                        successful = true;
                        noticeParams = {
                            variant: "success",
                            title: response.getState(),
                            message: "New enrollment address for the Physician has been successfully set."
                        };
                    } else {
                        noticeParams = {
                            variant: "error",
                            title: response.getState(),
                            message: "Unable to set new enrollment address for Physician. Please try again."
                        };
                    }
                    break;
                case "ERROR":
                    noticeParams = {
                        variant: "error",
                        title: response.getState(),
                        message: "Unable to set new enrollment address for Physician."
                    };
                    break;
                default:
                    noticeParams = {
                        variant: "error",
                        title: response.getState(),
                        message: "Unable to set new enrollment address for Physician: " + errorMsg
                    };
            }

            component.find("notifLib").showToast(noticeParams);

            if(successful) {
                this.finished(component);
            }
        });
    },

    finished : function(component) {
        component.set("v.account", null);
    }
});