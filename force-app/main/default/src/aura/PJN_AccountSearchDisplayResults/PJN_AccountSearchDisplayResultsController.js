({
    init: function (component, event, helper) {
        helper.initialize(component);
    },

    clearResults : function(component) {
        component.set("v.results", []);
    },

    setResults : function(component, event) {
        if (event.getParams().error) {
            console.error(event.getParams().error);
        } else {
            var accounts = event.getParams().result.map(function(result) {
                return result.singleResultByField;
            });
            component.set("v.results", accounts);
        }
    },

    handleRowAction: function (component, event, helper) {
        helper.handleAction(component, event);
    },

    displayNewForm: function(component, event, helper) {
        helper.showForm(component, true);
    },

    hideNewForm: function(component, event, helper) {
        helper.showForm(component, false);
    },

    assembleResults: function(component, event, helper) {
        helper.assembleResults(component);
    },
});