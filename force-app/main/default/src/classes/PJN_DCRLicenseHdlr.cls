/**
 * DCR License created trigger handler to create DCR and Lines when a license is inserted or updated
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_DCRLicenseHdlr implements PJN_TriggerDispatcher.HandlerInterface {

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

        List<PJN_License__c> licenses = new List<PJN_License__c>();
        for(PJN_License__c thisLicense : (List<PJN_License__c>) Trigger.new) {
            if(Trigger.isInsert && String.isNotBlank(thisLicense.PJN_Veeva_Network_Id__c)) {
                continue;
            }
            licenses.add(thisLicense);
        }

        Map<Id, Account> accountsMap = PJN_DCRCreateHelper.getAccountsRelatedMap(licenses);
        Map<Id, PJN_Contact_Information__c> addressesMap = getAddressesRelatedMap(licenses);

        buildDCRs(accountsMap, addressesMap, licenses);

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
     * Gets addresses related to the licenses in a map by address id
     * @param licenses  List of licenses to get Address from
     * @return  `Map<Id, PJN_Contact_Information__c>`
     */
    public static Map<Id, PJN_Contact_Information__c> getAddressesRelatedMap(List<PJN_License__c> licenses) {
        Set<Id> addressIds = new Set<Id>();

        for (PJN_License__c thisLicense : licenses) {
            if (thisLicense.PJN_Contact_Information__c == null) {
                continue;
            }

            addressIds.add(thisLicense.PJN_Contact_Information__c);
        }

        List<String> fieldNames = new List<String> {
            'Id',
            'RecordType.DeveloperName',
            'PJN_Veeva_Network_Id__c'
        };

        String query = 'SELECT ' +
            String.join(fieldNames, ',') + ' ' +
            'FROM ' + PJN_Contact_Information__c.sObjectType.getDescribe().getName() + ' ' +
            'WHERE Id IN :addressIds';

        return new Map<Id, PJN_Contact_Information__c> ((List<PJN_Contact_Information__c>) Database.query(String.escapeSingleQuotes(query)));
    }

    /**
     * Builds License and Parent Account DCRs
     * @param accountsMap   Retrieve Account record related to License using this map
     */
    private void buildDCRs(Map<Id, Account> accountsMap, Map<Id, PJN_Contact_Information__c> addressesMap, List<PJN_License__c> licenses) {
        for(PJN_License__c thisLicense : licenses) {
            Account parentAccount = accountsMap.get(thisLicense.PJN_Account__c);

            if (parentAccount == null) {
                continue;
            }

            PJN_DCR dcrWrapper = new PJN_DCR(
                parentAccount,
                (Trigger.isInsert ? null : (PJN_License__c) Trigger.oldMap.get(thisLicense.Id)),
                thisLicense
            );

            Boolean isAllowedToSend = dcrWrapper.parentDcr != null && dcrWrapper.dcr != null
                && !dcrWrapper.dcrLines.isEmpty();

            if (!isAllowedToSend) {
                continue;
            }

            dcrWrapper.addLicenseAddress(addressesMap.get(thisLicense.PJN_Contact_Information__c));

            parentDcrsByExtId.put(dcrWrapper.parentDcr.PJN_External_Id__c, dcrWrapper.parentDcr);
            dcrs.add(dcrWrapper.dcr);
            parentDcrLinesByExtId.put(dcrWrapper.parentDcr.PJN_External_Id__c, dcrWrapper.parentDcrLines);
            dcrLines.addAll(dcrWrapper.dcrLines);
        }
    }
}