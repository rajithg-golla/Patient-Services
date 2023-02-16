({
    init: function(component, helper, event) {
        const pageRef = component.get("v.pageReference");
        if (pageRef) {
            const state = pageRef.state; // state holds any query params
            console.log("state",JSON.parse(JSON.stringify(state)));
            let base64Context = state.inContextOfRef;

            // For some reason, the string starts with "1.", if somebody knows why,
            // this solution could be better generalized.
            if (base64Context) {
                if (base64Context.startsWith("1\.")) {
                    base64Context = base64Context.substring(2);
                }
                const addressableContext = JSON.parse(window.atob(base64Context));
                component.set("v.carePlanId", addressableContext.attributes.recordId);
            }
        } else {
            component.set("v.investigationId", component.get("v.recordId"));

        }
    },

    refreshTab: function() {
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
    }
})