({
    closeModal : function() {
        $A.get("e.force:closeQuickAction").fire();
    },

    complete : function() {
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
    }
});