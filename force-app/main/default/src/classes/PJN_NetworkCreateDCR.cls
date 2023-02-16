/**
 * Create Data change requests on Network
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkCreateDCR {

    /**
     * DCR Wrappers to convert to Network DCR structure
     */
    private List<PJN_DCR> dcrs;

    /**
     * Network DCR structures
     */
    private Map<String, PJN_NetworkRecord> networkDCRByExtId;

    /**
     * Constructor which converts DCR Wrappers passed to Network DCRs
     * @param dcrs  DCR Wrappers
     */
    public PJN_NetworkCreateDCR(List<PJN_DCR> dcrs) {
        this.dcrs = dcrs;

        this.networkDCRByExtId = new Map<String, PJN_NetworkRecord>();

        for (PJN_DCR dcrWrapper : dcrs) {
            Boolean hasStatusAllowed = dcrWrapper.dcr.PJN_Status__c == PJN_NetworkConstants.DCR_STATUS_PENDING
                && (dcrWrapper.parentDcr == null || dcrWrapper.parentDcr.PJN_Status__c == PJN_NetworkConstants.DCR_STATUS_PENDING);

            if (!hasStatusAllowed) {
                continue;
            }

            String currentExtId = getMainDCRExternalId(dcrWrapper);

            PJN_NetworkRecord networkDCR = this.networkDCRByExtId.containsKey(currentExtId) ?
                this.networkDCRByExtId.get(currentExtId) :
                new PJN_NetworkRecord(dcrWrapper);

            if (dcrWrapper.parentDcr != null) {
                networkDCR.addChildDCR(dcrWrapper);
            }

            this.networkDCRByExtId.put(currentExtId, networkDCR);
        }
    }

    /**
     * Get Main DCR External Id from dcr or parent dcr if exists
     * @param dcrWrapper    DCR Wrapper to obtain the external id from
     * @returns `String`
     */
    private String getMainDCRExternalId(PJN_DCR dcrWrapper) {
        return dcrWrapper.parentDcr != null ?
            dcrWrapper.parentDcr.PJN_External_Id__c.substringBeforeLast('|') :
            dcrWrapper.dcr.PJN_External_Id__c.substringBeforeLast('|');
    }

    /**
     * Send Network DCRs to the Network system
     * @returns `List<PJN_DCR>`
     */
    public List<PJN_DCR> sendDcrs() {
        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout('/change_request', 'POST', 'application/json');

        String networkCalloutBody = getnetworkDCRCalloutBodyFormat();
        System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Body callout: ' + networkCalloutBody);

        PJN_PublishTransactionLog.logType = 'DCR';

        PJN_NetworkResponse response = networkCallout.callVeevaNetwork(networkCalloutBody);

        if (response == null) {
            return new List<PJN_DCR>();
        }

        for (PJN_DCR dcrWrapper : dcrs) {
            Boolean hasStatusAllowed = dcrWrapper.dcr.PJN_Status__c == PJN_NetworkConstants.DCR_STATUS_PENDING;

            if (!hasStatusAllowed) {
                continue;
            }

            if (response.errors != null && !response.errors.isEmpty()) {
                String errorMessage = String.isNotBlank(response.errors[0].message) ?
                    response.errors[0].message :
                    response.responseMessage;

                dcrWrapper.dcr.PJN_Error__c = errorMessage;
                dcrWrapper.dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_CANCELLED;
                dcrWrapper.dcr.PJN_External_Id__c = dcrWrapper.dcr.Id;
                dcrWrapper.dcr.PJN_Sent_Datetime__c = System.now();

                if (dcrWrapper.parentDcr != null) {
                    dcrWrapper.parentDcr.PJN_Error__c = errorMessage;
                    dcrWrapper.parentDcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_CANCELLED;
                    dcrWrapper.parentDcr.PJN_External_Id__c = dcrWrapper.parentDcr.Id;
                    dcrWrapper.parentDcr.PJN_Sent_Datetime__c = System.now();
                }

                continue;
            }

            dcrWrapper.dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_SUBMITTED;
            dcrWrapper.dcr.PJN_Sent_Datetime__c = System.now();

            if (dcrWrapper.parentDcr != null) {
                dcrWrapper.parentDcr.PJN_DCR_External_Id__c = response.changeRequestId;
                dcrWrapper.parentDcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_SUBMITTED;
                dcrWrapper.parentDcr.PJN_Sent_Datetime__c = System.now();
                dcrWrapper.parentDcr.PJN_Veeva_Network_Id__c = String.isNotBlank(dcrWrapper.parentDcr.PJN_Veeva_Network_Id__c) ? dcrWrapper.parentDcr.PJN_Veeva_Network_Id__c : response.reservedVid;
            } else {
                dcrWrapper.dcr.PJN_DCR_External_Id__c = response.changeRequestId;
                dcrWrapper.dcr.PJN_Veeva_Network_Id__c = String.isNotBlank(dcrWrapper.dcr.PJN_Veeva_Network_Id__c) ? dcrWrapper.dcr.PJN_Veeva_Network_Id__c : response.reservedVid;
            }
        }

        return dcrs;
    }

    /**
     * Serialize Network DCRs to be valid for callout
     * @returns `String`
     */
    private String getnetworkDCRCalloutBodyFormat() {
        Map<String, Object> record = new Map<String, Object>();

        for (String networkDCRExtId : networkDCRByExtId.keySet()) {
            PJN_NetworkRecord thisNetworkDCR = networkDCRByExtId.get(networkDCRExtId);

            if (thisNetworkDCR == null) {
                continue;
            }

            String thisNetworkDCRSerialized = System.JSON.serialize(thisNetworkDCR, true);

            if (thisNetworkDCR.reserveVid) {
                record.put('reserve_vid', thisNetworkDCR.reserveVid);
            }

            record.put('metadata', getNetworkMetadata());
            record.put('entity_type', thisNetworkDCR.entityType);
            record.put('vid_key', thisNetworkDCR.vidKey);

            Map<String, Object> entity = new Map<String, Object>();
            entity.putAll(thisNetworkDCR.attributes);

            List<Object> networkAddresses = getChildNetworkCalloutBodyRecords(thisNetworkDCR.addresses);

            if (!networkAddresses.isEmpty()) {
                entity.put('addresses__v', networkAddresses);
            }

            List<Object> networkLicenses = getChildNetworkCalloutBodyRecords(thisNetworkDCR.licenses);

            if (!networkLicenses.isEmpty()) {
                entity.put('licenses__v', networkLicenses);
            }

            record.put('entity', entity);
        }

        return System.JSON.serialize(record);
    }

    private Map<String, Object> getNetworkMetadata() {
        PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;
        String systemName = pjnSetting != null ? pjnSetting.PJN_Network_System__c : PJN_NetworkConstants.NETWORK_SYSTEM;

        return new Map<String, Object> {
            'creator' => UserInfo.getUserName(),
            'system' => systemName,
            'note' => 'DCR created from ' + systemName,
            'source' => systemName
        };
    }

    private List<Object> getChildNetworkCalloutBodyRecords(List<PJN_NetworkRecord> childNetworkRecords) {
        List<Object> childNetworkCalloutBodyRecords = new List<Object>();

        if (childNetworkRecords != null && !childNetworkRecords.isEmpty()) {
            for (PJN_NetworkRecord childNetworkRecord : childNetworkRecords) {
                Map<String, Object> childNetworkCalloutBodyRecord = new Map<String, Object> {
                    'vid_key' => childNetworkRecord.vidKey
                };

                if (String.IsNotBlank(childNetworkRecord.licenseAddressVidKey)) {
                    childNetworkCalloutBodyRecord.put(PJN_NetworkConstants.NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD, childNetworkRecord.licenseAddressVidKey);
                }

                childNetworkCalloutBodyRecord.putAll(childNetworkRecord.attributes);

                if (String.IsNotBlank(childNetworkRecord.entityType)) {
                    childNetworkCalloutBodyRecord.put('type__v', childNetworkRecord.entityType);
                }

                childNetworkCalloutBodyRecords.add(childNetworkCalloutBodyRecord);
            }
        }

        return childNetworkCalloutBodyRecords;
    }
}