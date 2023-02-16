/**
 * Data Change Request Trigger handler to replace external id
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_SetExternalDCRIdHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.IsBefore && Trigger.isUpdate;

        if (!isAllowed) {
            return;
        }

        Id mergeRecordTypeId = Schema.SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByDeveloperName().get('PJN_Patient_Merge').getRecordTypeId();

        for(PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {

            if (dcr.RecordTypeId == mergeRecordTypeId) {
                continue;
            }

            PJN_Data_Change_Request__c oldDCR = (PJN_Data_Change_Request__c) Trigger.oldMap.get(dcr.Id);

            Boolean hasStatusChanged = oldDCR.PJN_Status__c != dcr.PJN_Status__c;

            if(!hasStatusChanged) {
                continue;
            }

            dcr.PJN_External_Id__c = String.isNotBlank(dcr.PJN_DCR_External_Id__c) ?
                dcr.PJN_DCR_External_Id__c :
                dcr.PJN_External_Id__c.substringBeforeLast('|');

            dcr.PJN_External_Id__c += '|' + dcr.PJN_Status__c;
        }
    }
}