({
    init : function(component) {
        const action = component.get("c.getFulfillmentRequest");
        action.setParams({
            "fulfillmentRequest": {
                PJN_Care_Plan__c: this.getInContextOfRefUrlParameterByName(component, "recordId"),
                RecordTypeId: component.get("v.pageReference").state.recordTypeId
            }
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    const fulfillmentRequest = response.getReturnValue();
                    const newFulfillmentEvent = $A.get("e.force:createRecord");
                    newFulfillmentEvent.setParams({
                        "entityApiName": "PJN_Fulfillment_Request__c",
                        "recordTypeId": fulfillmentRequest.RecordTypeId,
                        "defaultFieldValues": fulfillmentRequest
                    });
                    newFulfillmentEvent.fire();
                }
            );
        });
        $A.enqueueAction(action);
    },
    // get inContextOfRef url parameter and decode it to get to the attributes (here recordId)
    getInContextOfRefUrlParameterByName: function(component, name) {
        let inContextOfRef = "inContextOfRef";
        inContextOfRef = inContextOfRef.replace(/[\[\]]/g, "\\$&");
        const url = window.location.href;
        let regex = new RegExp("[?&]" + inContextOfRef + "(=1\.([^&#]*)|&|#|$)");
        let results = regex.exec(url);

        if (!results) {
            regex = new RegExp("https://.*/Case/([a-zA-Z0-9]+)/.*$");
            results = regex.exec(url);
            if (!results || !results[1]) {
                return null;
            }
            return results[1];
        }
        if (!results[2]) return "";

        const context = JSON.parse(window.atob(decodeURIComponent(results[2].replace(/\+/g, " "))));
        return context.attributes[name];
    }
});