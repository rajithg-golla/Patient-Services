({
    removeContactInfoRec: function(component) {
        var removeContactInfo = component.getEvent("removeContactInfo");
        removeContactInfo.setParams({
            "index": component.get("v.index")
        });
        removeContactInfo.fire();
    },

    editRecord: function(component) {
        const editContactInfo = component.getEvent("editContactInfo");
        editContactInfo.setParams({
            "index": component.get("v.index")
        });
        editContactInfo.fire();
    }
});