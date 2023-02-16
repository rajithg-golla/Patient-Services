({
    onTabFocused : function(component, event, helper) {
        var focusedTabId = event.getParam('currentTabId');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            if(tabId === focusedTabId){
                component.find("missinginfo").refresh();
            }
        });
    }
})