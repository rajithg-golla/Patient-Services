({
    init : function(component, event, helper) {
        helper.getAddresses(component);
        helper.getContactMetadata(component);
    },

    newAddress : function(component) {
        $A.util.removeClass(component.find("new-address"), "slds-hide");
        $A.util.removeClass(component.find("cancel-button"), "slds-hide");
        $A.util.addClass(component.find("new-address-button"), "slds-hide");
        $A.util.addClass(component.find("existing-addresses"), "slds-hide");
        $A.util.addClass(component.find("close-button"), "slds-hide");
    },

    cancel : function(component) {
        $A.util.addClass(component.find("new-address"), "slds-hide");
        $A.util.addClass(component.find("cancel-button"), "slds-hide");
        $A.util.removeClass(component.find("new-address-button"), "slds-hide");
        $A.util.removeClass(component.find("existing-addresses"), "slds-hide");
        $A.util.removeClass(component.find("close-button"), "slds-hide");
    },

    close : function(component) {
        component.set("v.account", null);
    },

    handlePrimaryAddressEvent : function(component, event, helper) {
        const recordId = event.getParam("id");
        helper.setPrimaryAddress(component, recordId);
    },

    handleNewAddressEvent : function(component, event, helper) {
        helper.addPrimaryAddress(component, event);
    }
});