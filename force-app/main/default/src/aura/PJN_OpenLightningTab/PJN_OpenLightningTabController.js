({
    init : function(component, event, helper) {
        const workspace = component.find("workspace");

        workspace.getFocusedTabInfo().then(function(response) {
            component.set("v.returnUrl", response.url);
            component.set("v.thisTabId", response.tabId);
        });

    },

    openTab : function(component, event, helper) {
        const tabId     = component.get("v.targetTabId");
        const workspace = component.find("workspace");

        if(tabId) {
            workspace.focusTab({tabId: tabId}).then(function(response) {
                // Set focus to existing tab
            }).catch(function(error) {
                // Tab is no longer present, so recreate it
                component.set("v.targetTabId", undefined);
                helper.openTarget(component);
            });
        } else {
            helper.openTarget(component);
        }
    },
});