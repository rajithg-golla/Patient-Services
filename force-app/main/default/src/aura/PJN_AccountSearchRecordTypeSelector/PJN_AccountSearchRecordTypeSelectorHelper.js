({
    loadPersonRecordTypes : function(component) {
        const getRecTypesAction = component.get("c.getAccountSearchRecordTypes");

        getRecTypesAction.setParams({ isPersonSearch: true});

        getRecTypesAction.setCallback(this, function(res) {
            const types = res.getReturnValue();
            component.set("v.personRecordTypes", types);
            this.setTab(component, "Person");
        });

        $A.enqueueAction(getRecTypesAction);
    },

    loadBusinessRecordTypes : function(component) {
        const getRecTypesAction = component.get("c.getAccountSearchRecordTypes");

        getRecTypesAction.setParams({ isPersonSearch: false});

        getRecTypesAction.setCallback(this, function(res) {
            const types = res.getReturnValue();
            component.set("v.businessRecordTypes", types);
        });

        $A.enqueueAction(getRecTypesAction);
    },

    setTab : function(component, tabname) {
        const priorRT = component.get("v.selectedRecordType");
        component.set("v.selectedAccountType", tabname);

        try {
            const firstRT = (tabname === "Person")
                ? component.get("v.personRecordTypes")[0].value
                : component.get("v.businessRecordTypes")[0].value;

            component.set("v.selectedRecordType", firstRT);

            if(priorRT === firstRT) {
                // The change event won't fire, so do it manually
                this.buildSelectedTypes(component);
            }
        } catch(err) {
            //Record types may not be initialized yet
            console.warn("Account Record Types not initialized");
        }
    },

    buildSelectedTypes : function(component) {
        const selected = component.get("v.selectedRecordType");

        if(selected && selected.length > 0) {
            component.set("v.selectedRecordTypes", [selected]);
        } else {
            //All has been selected, so provide all the record types
            this.buildSelectedList(component);
        }

        // Notify listeners that a new record type has been selected
        component.getEvent("recordTypeChangeEvent").fire();
    },

    buildSelectedList: function(component) {
        const source = component.get("v.selectedAccountType") === "Person"
            ? component.get("v.personRecordTypes")
            : component.get("v.businessRecordTypes");

        const rtList = [];
        source.forEach(function(item) {
            if(item.value) {
                rtList.push(item.value);
            }
        });

        component.set("v.selectedRecordTypes", rtList);
    }
});