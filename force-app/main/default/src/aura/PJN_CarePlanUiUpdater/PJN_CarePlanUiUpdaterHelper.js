({
    subscribe : function(component) {
        const empApi = component.find("empApi");
        const channel = "/event/PJN_Care_Plan_Update__e";
        const replayId = -1;

        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            const carePlanId = component.get("v.carePlanId");
            if(eventReceived.data
                && eventReceived.data.payload
                && eventReceived.data.payload.PJN_Care_Plan_Ids_List__c
                && eventReceived.data.payload.PJN_Care_Plan_Ids_List__c.includes(carePlanId)) {
                component.getEvent("carePlanUpdated").fire();
            }
        })).then(subscription => {
            console.log("Subscribed to channel ", subscription.channel);
        });
    }
});