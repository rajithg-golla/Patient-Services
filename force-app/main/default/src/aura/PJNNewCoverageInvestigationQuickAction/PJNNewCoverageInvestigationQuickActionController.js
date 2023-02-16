({
    init : function(component, event, helper) {
        const action = component.get("c.getInvestigationCarePlanId");
        action.setParams({investigationId: component.get("v.recordId")});
        action.setCallback(this, function(response) {
            component.set("v.carePlanId", response.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    openTab: function(component, event, helper) {
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabInfo()
            .then(function(parentTab)  {
                workspaceAPI.openSubtab({
                    parentTabId: parentTab.tabId,
                    url: `#/sObject/${event.getParam("investigationId")}/view`,
                    focus: true
                }, true);
            });
    }
})