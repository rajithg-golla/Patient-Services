({
    getFilesListOptions : function(component) {
        const caseId = component.get("v.caseId");
        if (caseId) {
            component.set("v.loading", true);

            const getFilesAction = component.get("c.getFileOptions");
            getFilesAction.setParams({ caseId });

            getFilesAction.setCallback(this, function(response) {
                const options = response.getReturnValue();
                component.set("v.fileOptions", options);
                if (options.length === 1) {
                    component.set("v.selectedFileId", options[0].documentId);
                }

                component.set("v.loading", false);
            });

            $A.enqueueAction(getFilesAction);
        }
    },

    handleFileChange : function(component) {
        component.set("v.selectedFileId", component.find("fileSelect").get("v.value") || "");
    }
});