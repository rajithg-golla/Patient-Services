/**
 * Data Change Request Trigger handler to replace License Address related when it's needed
 * @author  Mavens
 * @group   DCR
 */
public with sharing class PJN_SetDCRLicenseAddressHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handler
     */
    public void handle() {
        Boolean isAllowed = Trigger.IsBefore && Trigger.isUpdate;

        if (!isAllowed) {
            return;
        }

        Set<String> licenseAddressNetworkIds = new Set<String>();

        for(PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {
            PJN_Data_Change_Request__c oldDCR = (PJN_Data_Change_Request__c) Trigger.oldMap.get(dcr.Id);

            Boolean hasLicenseAddressChanged = oldDCR.PJN_License_Address_Network_Id__c != dcr.PJN_License_Address_Network_Id__c;

            if(!hasLicenseAddressChanged) {
                continue;
            }

            if (String.IsBlank(dcr.PJN_License_Address_Network_Id__c)) {
                dcr.PJN_License_Address__c = null;
            } else {
                licenseAddressNetworkIds.add(dcr.PJN_License_Address_Network_Id__c);
            }
        }

        Map<String, Id> addressIdByNetworkIds = getAddressIdByNetworkIds(licenseAddressNetworkIds);

        if (addressIdByNetworkIds.isEmpty()) {
            return;
        }

        for (PJN_Data_Change_Request__c dcr : (List<PJN_Data_Change_Request__c>) Trigger.new) {
            if (addressIdByNetworkIds.containsKey(dcr.PJN_License_Address_Network_Id__c)) {
                dcr.PJN_License_Address__c = addressIdByNetworkIds.get(dcr.PJN_License_Address_Network_Id__c);
            }
        }
    }

    private static Map<String, Id> getAddressIdByNetworkIds(Set<String> licenseAddressNetworkIds) {
        Map<String, Id> addressIdByNetworkIds = new Map<String, Id>();

        if (licenseAddressNetworkIds.isEmpty()) {
            return addressIdByNetworkIds;
        }

        List<PJN_Contact_Information__c> addresses = [
            SELECT
                Id,
                PJN_Veeva_Network_Id__c
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Veeva_Network_Id__c IN :licenseAddressNetworkIds
        ];

        for (PJN_Contact_Information__c address : addresses) {
            addressIdByNetworkIds.put(address.PJN_Veeva_Network_Id__c, address.Id);
        }

        return addressIdByNetworkIds;
    }
}