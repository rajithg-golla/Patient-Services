({
    close : function() {
        $A.get("e.force:closeQuickAction").fire();
    },
    reload : function () {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
})