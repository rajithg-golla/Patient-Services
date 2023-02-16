({
    initialize : function(component) {
        const selectedResult = component.get("v.selectedResult");

        if (!selectedResult.originalResult
            || !selectedResult.originalResult.accountDetail
            || !selectedResult.originalResult.accountDetail.PJN_Contact_Information__r) {
            return;
        }
        const contactInfoList = selectedResult.originalResult.accountDetail.PJN_Contact_Information__r;
        
        const contactInfoByRecTypeName = contactInfoList.reduce(
            function(accumulator, contactInfo) {
                const recTypeName = contactInfo.RecordType.Name;
                if (!accumulator[recTypeName]) {
                    accumulator[recTypeName] = {
                        fields: ["PJN_Phone__c", "PJN_Postal_Code__c", "RecordTypeId"],
                        records: []
                    };
                }
                accumulator[recTypeName].records.push(contactInfo);
                return accumulator;
            },
            {}
        );

        const tiles = [];
        const recTypes = Object.keys(contactInfoByRecTypeName);
        for (let i=0; i<recTypes.length; i++) {
            tiles.push({
                title: recTypes[i],
                records: contactInfoByRecTypeName[recTypes[i]].records,
                fields: contactInfoByRecTypeName[recTypes[i]].fields
            });
        }
        component.set("v.tiles", tiles);
    }
});