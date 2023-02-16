/**
 * Data Change Request Trigger handler to replace dcr type when it's needed
 * @author  Mavens
 * @group   DCR
 */
public with sharing class PJN_SetDCRTypeHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.IsBefore && Trigger.isUpdate;

        if (!isAllowed) {
            return;
        }

        List<SObject> recordsToUpdate = new List<SObject>();

        for(PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {
            PJN_Data_Change_Request__c oldDCR = (PJN_Data_Change_Request__c) Trigger.oldMap.get(dcr.Id);

            Boolean isDCRTypeChanged = String.IsNotBlank(oldDCR.PJN_Type__c) && oldDCR.PJN_Type__c != dcr.PJN_Type__c;

            if(!isDCRTypeChanged) {
                continue;
            }

            dcr.PJN_Type__c = oldDCR.PJN_Type__c;
        }
    }
}