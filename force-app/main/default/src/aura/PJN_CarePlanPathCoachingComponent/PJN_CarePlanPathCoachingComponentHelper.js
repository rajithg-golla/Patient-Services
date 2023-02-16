({
    componentChange : function(component) {
        this.loadComponent(component);
        this.setClassForMode(component);
    },
    setClassForMode : function(component) {
        const mode = component.get("v.componentRecord").PJN_Mode__c;
        const componentContainer = component.find("componentContainer");
        if(mode === "A") {
            $A.util.addClass(componentContainer, "slds-path__keys");
        } else if(mode === "B") {
            $A.util.addClass(componentContainer, "slds-path__guidance");
        } else if(mode === "C") {
            $A.util.addClass(componentContainer, "slds-path__flexible");
        }
    },
    loadComponent : function(component) {
        const componentRecord = component.get("v.componentRecord");
        const problemRecord = component.get("v.problemRecord");
        const hasActions = component.get("v.hasActions");
        if(componentRecord) {
            $A.createComponent(
                "c:" + componentRecord.PJN_Component_Name__c,
                {
                    componentRecord: componentRecord,
                    problemRecord: problemRecord,
                    hasActions: hasActions,
                    context: component.get("v.context")
                },
                function(newComponent, status, errorMessage) {
                    if(status === "SUCCESS") {
                        component.set("v.body", newComponent);
                    }
                    else if(status === "INCOMPLETE" || status === "ERROR") {
                        if(errorMessage === null) {
                            errorMessage = "No response from server or client is offline.";
                        }
                        const context = component.get("v.context");
                        if(context) {
                            sforce.one.showToast({
                                title: "Error",
                                type: "error",
                                message: errorMessage
                            });
                        } else {
                            const toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                title: "Error",
                                type: "error",
                                message: errorMessage
                            });
                            toastEvent.fire();
                        }
                    }
                }
            );
        }
    }
});