({
    init : function(component) {
        const entityApiName = component.get("v.sObjectName");
        const action = component.get("c.getCarePlanChildMapped");
        action.setParams({
            "carePlanId": this.getInContextOfRefUrlParameterByName(component, "recordId"),
            "sobjectName": entityApiName,
            "recordTypeId": component.get("v.pageReference").state.recordTypeId
        });
        action.setCallback(this, function(response) {
            var toastErrorHandler = component.find("toastErrorHandler");
            toastErrorHandler.handleResponse(
                response,
                function(response) {
                    const sobjectRecord = response.getReturnValue();
                    const newSObjectEvent = $A.get("e.force:createRecord");
                    newSObjectEvent.setParams({
                        "entityApiName": entityApiName,
                        "recordTypeId": sobjectRecord.RecordTypeId,
                        "defaultFieldValues": sobjectRecord
                    });
                    newSObjectEvent.fire();
                }
            );
        });
        $A.enqueueAction(action);
    },
    // get inContextOfRef url parameter and decode it to get to the attributes (here recordId)
    getInContextOfRefUrlParameterByName: function(component, name) {
        var pageRef = component.get("v.pageReference");
        var state = pageRef.state;
        var base64Context = state.inContextOfRef;
        if (!base64Context) return null;
        if (!base64Context[2]) return "";
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        return addressableContext.attributes[name];
    }
});