({
    handlePreview : function(cmp, event) {
        let docId = event.getParam('docId');

        var workspaceAPI = cmp.find('workspace');
        workspaceAPI.getFocusedTabInfo().then(function (tabInfo) {
            return workspaceAPI.openSubtab({
                parentTabId: tabInfo.tabId,
                url: `/lightning/r/ContentDocument/${docId}/view`,
                focus: true
            });
        }).catch(function (error) {
            console.log('redirect error ', error.message);
        }.bind(this));
    }
});