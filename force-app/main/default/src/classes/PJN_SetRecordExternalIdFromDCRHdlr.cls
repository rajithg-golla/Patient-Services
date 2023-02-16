/**
 * Data Change Request Trigger handler to replace record external id
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_SetRecordExternalIdFromDCRHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.IsAfter && Trigger.isUpdate;

        if (!isAllowed) {
            return;
        }

        List<SObject> recordsToUpdate = new List<SObject>();

        for(PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {
            PJN_Data_Change_Request__c oldDCR = (PJN_Data_Change_Request__c) Trigger.oldMap.get(dcr.Id);

            Boolean hasExternalIdChanged = oldDCR.PJN_Veeva_Network_Id__c != dcr.PJN_Veeva_Network_Id__c;

            if(!hasExternalIdChanged) {
                continue;
            }

            if (dcr.PJN_Account__c != null) {
                recordsToUpdate.add(
                    new Account(
                        Id = dcr.PJN_Account__c,
                        PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                    )
                );
            } else if (dcr.PJN_Contact_Information__c != null) {
                recordsToUpdate.add(
                    new PJN_Contact_Information__c(
                        Id = dcr.PJN_Contact_Information__c,
                        PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                    )
                );
            } else if (dcr.PJN_License__c != null) {
                recordsToUpdate.add(
                    new PJN_License__c(
                        Id = dcr.PJN_License__c,
                        PJN_Veeva_Network_Id__c = dcr.PJN_Veeva_Network_Id__c
                    )
                );
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            PJN_DCR.updateFromNetwork = true;
            update recordsToUpdate;
            PJN_DCR.updateFromNetwork = false;
        }
    }
}