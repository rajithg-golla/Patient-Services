({
    init : function(component) {
        const activeComponent = component.get("v.activeComponent");
        const action = component.get("c.getEnrollmentWizardRecordForms");
        action.setParams({
            "componentSettingId": activeComponent.Id
        });
        action.setCallback(this, function(response) {
            const toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    const setting = response.getReturnValue()["setting"];
                    if (setting.PJN_Edit_Care_Plan_Record_Form__c) {
                        component.set("v.recordId", component.get("v.carePlanId"));
                    } else {
                        component.set("v.recordId", "null");
                    }
                    component.set("v.sObjectType", setting.PJN_SObject_API_Name__c);
                    component.set("v.recordTypeId", setting.PJN_RecordType_DeveloperName__c);
                    component.set("v.fields", response.getReturnValue()["fields"]);
                    component.set("v.carePlanFieldName", setting.PJN_Care_Plan_Lookup_Field_API_Name__c);
                    component.set("v.title", activeComponent.PJN_Section_Title__c);
                }
            );

            component.set("v.isSaving", false);
        });
        $A.enqueueAction(action);
    },
    refreshEvent : function(component, event) {
        component.set("v.recordId", event.getParam("recordId"));
    },
    load : function(component) {
        this.setDirtyMessage(component, "");
    },
    success : function(component, event) {
        const sourceId = event.getSource().getLocalId();
        let msg = $A.get("$Label.c.PJN_Creation_Record_Success_Message");
        if (sourceId == "formEditor") {
            msg = $A.get("$Label.c.PJN_Update_Record_Success_Message");
        }

        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": msg,
            "type": "success"
        });
        toastEvent.fire();

        const enrollmentStepEvent = component.getEvent("enrollmenWizardStepEvent");
        enrollmentStepEvent.setParams({
            "refresh" : true
        });
        enrollmentStepEvent.fire();

        component.set("v.isSaving", false);
        this.setDirtyMessage(component, "");
    },
    error : function( component) {
        component.set("v.isSaving", false);
        const reject = component.get("v.onNextReject");
        if (reject) {
            reject();
        }
    },
    change : function(component, event) {
        const helper = this;
        const fieldObject = component.find("field");
        if (Array.isArray(fieldObject)) {
            fieldObject.forEach(function(field) {
                helper.checkFieldChange(component, field);
            });
        } else {
            helper.checkFieldChange(component, fieldObject);
        }
    },
    checkFieldChange : function(component, field) {
        const helper = this;
        const value = field.get("v.value");

        // check string with a regex to validate if it is an ID, therefore, a lookup field
        const mayBeLookupField = /[a-zA-Z0-9]{18}|[a-zA-Z0-9]{15}/.test(value);

        if (value && mayBeLookupField) {
            const action = component.get("c.getIsValidLookupId");
            action.setParams({
                "lookupId": value
            });
            action.setCallback(this, function(response) {
                const toastErrorHandler = component.find("toastErrorHandler");
                toastErrorHandler.handleResponse(
                    response,
                    function(response) {
                        const isValidLookupId = response.getReturnValue();

                        if (isValidLookupId) {
                            helper.setDirtyMessage(component, $A.get("$Label.c.PJN_Unsaved_Changes"));
                            return;
                        }

                        field.reset();

                        const resetValue = field.reset();
                        if((value || resetValue) && (value !== resetValue)) {
                            field.set("v.value", value);
                            helper.setDirtyMessage(component, $A.get("$Label.c.PJN_Unsaved_Changes"));
                        }
                    }
                );
            });

                $A.enqueueAction(action);
            }

    },
    cancel : function(component, event) {
        event.preventDefault();
        this.setDirtyMessage(component, "");
        if (component.get("v.recordId") == "null") {
            const enrollmentStepEvent = component.getEvent("enrollmenWizardStepEvent");
            enrollmentStepEvent.setParams({
                "refresh" : true,
                "recordId" : null
            });
            enrollmentStepEvent.fire();
        } else {
            component.set("v.recordId", "null");
        }
    },
    submit : function(component, event) {
        component.set("v.isSaving", true);
        event.preventDefault();
        const eventFields = event.getParam("fields");
        eventFields[component.get("{!v.carePlanFieldName}")] = component.get("v.carePlanId");
        const formCreatorSubmit = component.find("formCreator");
        const formEditorSubmit = component.find("formEditor");
        if(formCreatorSubmit) {
            formCreatorSubmit.submit(eventFields);
        } else if(formEditorSubmit) {
            formEditorSubmit.submit(eventFields);
        }
    },
    setDirtyMessage: function(component, message) {
        component.set("v.formIsDirty", message.length > 0);
        const dirtyMap = component.get("v.dirtyComponentMap");
        const activeComponent = component.get("v.activeComponent");
        dirtyMap[activeComponent.Id] = message;
        component.set("v.dirtyComponentMap", dirtyMap);
    }
});