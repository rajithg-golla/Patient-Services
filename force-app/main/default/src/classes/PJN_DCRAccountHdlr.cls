/**
 * DCR Account create trigger handler to create DCR and Lines when an account is inserted or updated
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRAccountHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    private static Boolean hasRun = false;

    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) && !PJN_DCR.updateFromNetwork;

        if(!isAllowed || hasRun) {
            return;
        }

        List<PJN_Data_Change_Request__c> dcrs = new List<PJN_Data_Change_Request__c>();
        List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

        List<Account> accountsToUpdate = new List<Account>();

        for(Account thisAccount : (List<Account>) Trigger.new) {
            if(Trigger.isInsert && String.isNotBlank(thisAccount.PJN_Veeva_Network_Id__c)) {
                continue;
            }

            PJN_DCR dcrWrapper = new PJN_DCR(
                (Trigger.isInsert ? null : (Account) Trigger.oldMap.get(thisAccount.Id)),
                thisAccount
            );

            Boolean isAllowedToSend = dcrWrapper.dcr != null && !dcrWrapper.dcrLines.isEmpty();

            if (!isAllowedToSend) {
                continue;
            }

            dcrs.add(dcrWrapper.dcr);
            dcrLines.addAll(dcrWrapper.dcrLines);

            if (Trigger.isUpdate && dcrWrapper.revertValueByFieldName != null && !dcrWrapper.revertValueByFieldName.isEmpty()) {
                Account accountToUpdate = new Account (
                    Id = thisAccount.Id
                );
                for (String fieldName : dcrWrapper.revertValueByFieldName.keySet()) {
                    accountToUpdate.put(fieldName, dcrWrapper.revertValueByFieldName.get(fieldName));
                }

                accountsToUpdate.add(accountToUpdate);
            }
        }

        if(!dcrs.isEmpty() && !dcrLines.isEmpty()) {
            upsert dcrs PJN_External_Id__c;
            PJN_DCRCreateHelper.upsertDCRLines(dcrLines);

            Map<Id, String> errorMessageByDCRId = PJN_NetworkEventHelper.publishDCRs(dcrs);
            updateDCRsWithError(dcrs, errorMessageByDCRId);
        }

        if (!accountsToUpdate.isEmpty()) {
            hasRun = true;
            update accountsToUpdate;
        }
    }

    /**
     * Handles DCRs with error to update them to Cancelled
     * @param dcrs                  List of DCRs
     * @param errorMessageByDCRId   Map of error messages by DCR id
     */
    @testVisible
    private void updateDCRsWithError(List<PJN_Data_Change_Request__c> dcrs, Map<Id, String> errorMessageByDCRId) {
        if (errorMessageByDCRId == null || errorMessageByDCRId.isEmpty()) {
            return;
        }

        List<PJN_Data_Change_Request__c> updateDCRs = new List<PJN_Data_Change_Request__c>();

        for(PJN_Data_Change_Request__c dcr : dcrs) {
            if (!errorMessageByDCRId.containsKey(dcr.Id)) {
                continue;
            }

            dcr.PJN_Error__c = errorMessageByDCRId.get(dcr.Id);
            dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_CANCELLED;
            dcr.PJN_Sent_Datetime__c = System.now();

            updateDCRs.add(dcr);
        }

        if (updateDCRs != null && !updateDCRs.isEmpty()) {
            update updateDCRs;
        }
    }
}