/**
 * DCR Address create trigger handler to create DCR and Lines when an address is inserted or updated
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRAddressHdlr implements PJN_TriggerDispatcher.HandlerInterface {


    private Map<String, PJN_Data_Change_Request__c> parentDcrsByExtId = new Map<String, PJN_Data_Change_Request__c>();
    private Map<String, List<PJN_Data_Change_Request_Line__c>> parentDcrLinesByExtId = new Map<String, List<PJN_Data_Change_Request_Line__c>>();
    private List<PJN_Data_Change_Request__c> dcrs = new List<PJN_Data_Change_Request__c>();
    private List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

    /**
     * Handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) && !PJN_DCR.updateFromNetwork;

        if(!isAllowed) {
            return;
        }

        Map<Id, Account> accountsMap = PJN_DCRCreateHelper.getAccountsRelatedMap(Trigger.new);

        buildDCRs(accountsMap);

        if(!parentDcrsByExtId.isEmpty() && !dcrs.isEmpty() && !dcrLines.isEmpty() && !parentDcrLinesByExtId.isEmpty()) {
            upsert parentDcrsByExtId.values() PJN_External_Id__c;
            upsert dcrs PJN_External_Id__c;

            for (List<PJN_Data_Change_Request_Line__c> parentDcrLines : parentDcrLinesByExtId.values()) {
                dcrLines.addAll(parentDcrLines);
            }
            PJN_DCRCreateHelper.upsertDCRLines(dcrLines);

            Map<Id, String> errorMessageByDCRId = PJN_NetworkEventHelper.publishDCRs(parentDcrsByExtId.values());
            List<PJN_Data_Change_Request__c> allDCRs = dcrs;
            allDCRs.addAll(parentDcrsByExtId.values());
            PJN_DCRCreateHelper.updateDCRsWithError(allDCRs, errorMessageByDCRId);
        }
    }

    /**
     * Builds Address and Parent Account DCRs
     * @param accountsMap   Retrieve Account record related to Address using this map
     */
    private void buildDCRs(Map<Id, Account> accountsMap) {
        for(PJN_Contact_Information__c thisAddress : (List<PJN_Contact_Information__c>) Trigger.new) {
            Account parentAccount = accountsMap.get(thisAddress.PJN_Account__c);

            if (parentAccount == null) {
                continue;
            }

            PJN_DCR dcrWrapper = new PJN_DCR(
                parentAccount,
                (Trigger.isInsert ? null : (PJN_Contact_Information__c) Trigger.oldMap.get(thisAddress.Id)),
                thisAddress
            );

            Boolean isAllowedToSend = dcrWrapper.parentDcr != null && dcrWrapper.dcr != null
                && !dcrWrapper.dcrLines.isEmpty();

            if (!isAllowedToSend) {
                continue;
            }

            parentDcrsByExtId.put(dcrWrapper.parentDcr.PJN_External_Id__c, dcrWrapper.parentDcr);
            dcrs.add(dcrWrapper.dcr);
            parentDcrLinesByExtId.put(dcrWrapper.parentDcr.PJN_External_Id__c, dcrWrapper.parentDcrLines);
            dcrLines.addAll(dcrWrapper.dcrLines);
        }
    }
}