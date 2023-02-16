({
    doInit : function(component, event, helper) {
        const records = component.get("v.records");
        const fields = component.get("v.fields");

        const rows = records.map(
            function(record) {
                console.log("record", record);
                return fields.map(
                    function (field) {
                        console.log("field", field);
                        return record[field];
                    }
                );
            }
        );

        console.log(rows);

        component.set("v.rows", rows);
    }
});