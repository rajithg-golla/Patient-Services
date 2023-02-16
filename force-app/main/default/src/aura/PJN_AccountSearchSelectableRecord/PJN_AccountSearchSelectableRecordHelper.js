({
    setValues : function(component) {
        const record = component.get("v.record");
        const fields = component.get("v.fields").split(",");

        let values = [];
        fields.forEach(function(field) {
            values.push(record[field]);
        });

        component.set("v.values", values);
    },

    selectRecord : function(component) {
        var cmpEvent = component.getEvent("recordSelectedEvent");
        cmpEvent.setParams({ id: component.get("v.record").Id });
        cmpEvent.fire();
    }
});