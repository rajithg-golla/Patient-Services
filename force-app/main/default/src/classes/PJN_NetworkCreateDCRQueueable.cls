/**
 * Queue Network create DCR for a bunch of records
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkCreateDCRQueueable implements Queueable, Database.AllowsCallouts {

    /**
     *  List of main Data change Request (Always account record)
     */
    private List<PJN_Data_Change_Request__c> dcrs;

    /**
     * Map of List of Data change requests by main data change request id
     */
    private Map<Id, List<PJN_Data_Change_Request__c>> dcrChildrenByParentId;

    /**
     * Initialize main and child DCRs obtaining main DCRs
     * @param dcrs
     */
    public PJN_NetworkCreateDCRQueueable(Set<Id> dcrIds) {
        this.dcrs = PJN_DCRQuery.queryWithLinesByIds(dcrIds);

        List<PJN_Data_Change_Request__c> dcrChildren = PJN_DCRQuery.getPendingWithLinesByParentDCRs(this.dcrs);

        if (!dcrChildren.isEmpty()) {
            this.dcrChildrenByParentId = new Map<Id, List<PJN_Data_Change_Request__c>>();

            for (PJN_Data_Change_Request__c dcrChild : dcrChildren) {
                List<PJN_Data_Change_Request__c> currentDcrChildren = this.dcrChildrenByParentId.containsKey(dcrChild.PJN_Parent_Data_Change_Request__c) ?
                    this.dcrChildrenByParentId.get(dcrChild.PJN_Parent_Data_Change_Request__c) :
                    new List<PJN_Data_Change_Request__c>();

                currentDcrChildren.add(dcrChild);
                this.dcrChildrenByParentId.put(dcrChild.PJN_Parent_Data_Change_Request__c, currentDcrChildren);
            }
        }
    }

    /**
     * Queue execute method which converts DCR to Network DCR and send them to Veeva Network
     * @param context
     */
    public void execute(QueueableContext context) {
        if (PJN_NetworkCallout.noRunInTest || dcrs == null || dcrs.isEmpty()) {
            return;
        }

        List<PJN_DCR> dcrWrappers = new List<PJN_DCR>();

        // Limits body callout to 2000 records
        // Avoids callout issue or truncate body when number of character in callout body is quite high
        Integer lastListIndex = dcrs.size()-1;
        Integer minIndex = (lastListIndex - 2000) >= 0 ?
            lastListIndex - 2000 :
            0;

        for (Integer dcrIndex = lastListIndex; dcrIndex >= minIndex; dcrIndex--) {
            PJN_Data_Change_Request__c dcr = dcrs.remove(dcrIndex);

            List<PJN_Data_Change_Request__c> dcrChildren = dcrChildrenByParentId != null && dcrChildrenByParentId.containsKey(dcr.Id) ?
                dcrChildrenByParentId.get(dcr.Id) :
                new List<PJN_Data_Change_Request__c>();

            if (dcrChildren.isEmpty()) {
                dcrWrappers.add(new PJN_DCR(dcr));
                continue;
            }

            for (PJN_Data_Change_Request__c dcrChild : dcrChildren) {
                dcrWrappers.add(new PJN_DCR(dcrChild, dcr));
            }
        }

        if (!dcrWrappers.isEmpty()) {
            PJN_NetworkCreateDCR networkCreateDCRs = new PJN_NetworkCreateDCR(dcrWrappers);
            dcrWrappers = networkCreateDCRs.sendDcrs();

            Map<Id, PJN_Data_Change_Request__c> updateDCRsMap = new Map<Id, PJN_Data_Change_Request__c>();

            for (PJN_DCR dcrWrapper : dcrWrappers) {
                updateDCRsMap.put(dcrWrapper.dcr.Id, dcrWrapper.dcr);

                if (dcrWrapper.parentDcr != null) {
                    updateDCRsMap.put(dcrWrapper.parentDcr.Id, dcrWrapper.parentDcr);
                }
            }

            update updateDCRsMap.values();
        }


        if (!dcrs.isEmpty()) {
            System.enqueueJob(this);
        }
    }
}