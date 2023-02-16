/**
 * Queue DCRs from Event DCRs
 * @author  Mavens
 * @group   DCR
 */
public with sharing class PJN_NetworkQueueHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handler
     */
    public void handle() {
        Set<Id> dcrIds = new Set<Id>();
        Set<Id> outcomeIds = new Set<Id>();

        for(PJN_Veeva_Network__e networkEvent : (List<PJN_Veeva_Network__e>) Trigger.new) {
            if (networkEvent.PJN_DCR_Id__c != null && !dcrIds.contains(networkEvent.PJN_DCR_Id__c)) {
                dcrIds.add(networkEvent.PJN_DCR_Id__c);
            }
        }

        if (!dcrIds.isEmpty()) {
            PJN_NetworkCreateDCRQueueable networkCreateDCRQueue = new PJN_NetworkCreateDCRQueueable(dcrIds);
            System.enqueueJob(networkCreateDCRQueue);
        }
    }
}