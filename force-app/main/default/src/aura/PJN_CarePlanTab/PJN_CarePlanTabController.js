({
    handleRecordUpdate: function(component) {
        const caseFields = component.get("v.caseFields");
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId()
            .then(function(tabId) {
                console.log("caseFields",JSON.parse(JSON.stringify(caseFields)));
                const label = caseFields.Subject;
                workspaceAPI.setTabLabel({tabId, label});
            })
            .catch(function(error) {
                console.log("error",JSON.parse(JSON.stringify(error)));
            });
    }
});