({
    init : function(component) {
        const c__recordId = component.get("v.recordId");
        const workspace = component.find("workspace");

        workspace.getFocusedTabInfo()
            .then( focusedTabInfo => {
                workspace.openSubtab({
                    pageReference: {
                        type: "standard__component",
                        attributes: {
                            componentName: "c__PJN_AccountSearchGeneral"
                        },
                        state: { c__recordId },
                    },
                    focus: true,
                    parentTabId: focusedTabInfo.tabId
                });
            })
            .catch( error => console.error(`Unable to openAccountSearch as subtab ${error}`))
            .finally( () => $A.get("e.force:closeQuickAction").fire());
    }
});