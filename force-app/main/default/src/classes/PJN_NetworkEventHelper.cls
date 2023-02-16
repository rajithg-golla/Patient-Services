/**
 * Helper to create and publish events for Network
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkEventHelper {

    /**
     * Max Publish tries
     */
    private static final Integer PUBLISH_MAX_LIMIT = 10;

    /**
     * Publish DCR Count tries
     */
    private static Integer publishDCRCount = 0;

    /**
     * Publish CCS events with DCR Ids to be sent into CCS
     * @param dcrs  List of Data change requests
     * @returns `Map<Id, String>`
     */
    public static Map<Id, String> publishDCRs(List<PJN_Data_Change_Request__c> dcrs) {
        PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;
        Boolean isNetworkAllowed = pjnSetting != null ? pjnSetting.PJN_Veeva_Network__c : false;

        if (!isNetworkAllowed) {
            return null;
        }

        Map<Id, String> errorMessageByDCRId = new Map<Id, String>();
        List<PJN_Data_Change_Request__c> republishDCRs = new List<PJN_Data_Change_Request__c>();

        List<PJN_Veeva_Network__e> networkEvents = new List<PJN_Veeva_Network__e>();

        for(PJN_Data_Change_Request__c parentDCR : dcrs) {
            networkEvents.add(
                new PJN_Veeva_Network__e(
                    PJN_DCR_Id__c = parentDCR.Id
                )
            );
        }

        publishDCRCount++;
        List<Database.SaveResult> networkEventResults = EventBus.publish(networkEvents);

        for (Integer networkEventResultIndex = 0; networkEventResultIndex < networkEventResults.size(); networkEventResultIndex++) {
            Database.SaveResult networkEventResult = networkEventResults[networkEventResultIndex];
            PJN_Veeva_Network__e networkEvent = networkEvents[networkEventResultIndex];

            if (!networkEventResult.isSuccess() && publishDCRCount <= PUBLISH_MAX_LIMIT) {
                republishDCRs.add(new PJN_Data_Change_Request__c(Id = networkEvent.PJN_DCR_Id__c));
            } else if (!networkEventResult.isSuccess()) {
                for (Database.Error error : networkEventResult.getErrors()) {
                    errorMessageByDCRId.put(networkEvent.PJN_DCR_Id__c, error.getMessage());
                    System.debug(LoggingLevel.ERROR, PJN_NetworkConstants.NETWORK_DEBUG + '::Error: ' + error.getMessage());
                }
            }
        }

        if (publishDCRCount <= PUBLISH_MAX_LIMIT && !republishDCRs.isEmpty()) {
            errorMessageByDCRId.putAll(publishDCRs(republishDCRs));
        }

        publishDCRCount = 0;

        return errorMessageByDCRId;
    }
}