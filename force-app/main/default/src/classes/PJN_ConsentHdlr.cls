/**
 * @author Mavens
 * @date Mar 2019
 * @description Create/Update channel consents and contact point type consents when the user
 *              Opts-In or Opts-Out a contact information record
 * @group Consent
 */
public without sharing class PJN_ConsentHdlr {

    public static final String OPT_IN = 'Opt In';
    public static final String OPT_OUT = 'Opt Out';

    /**
     * If there is an existing channel consent for a contact information record, update the
     * effective from/to dates and the privacy consent status, if not create a new one.
     * @param  contactInfoIdsList   list of contact information records to process
     * @param  programDeveloperName program developer name
     * @param  consentType          consent type
     */
    public static void processConsentForContactInformation(List<Id> contactInfoIdsList,
                                                            String programDeveloperName,
                                                            String consentType) {
        Map<Id, PJN_Contact_Information__c> contactInfoMap = getContactInfoMap(contactInfoIdsList);
        Map<Id, PJN_Channel_Consent__c> channelConsentByContactInfoId = getExistingChannelConsentByContactInfoId(contactInfoIdsList);
        List<DataUsePurpose> dataUsePurposeList = getDataUsePurpose(programDeveloperName);

        if (!dataUsePurposeList.isEmpty()) {
            DataUsePurpose dataUsePurpose = dataUsePurposeList.get(0);
            PJN_Channel_Consent__c channelConsent;
            for (Id contactInfoId : contactInfoIdsList) {
                if (channelConsentByContactInfoId.containsKey(contactInfoId)) {
                    channelConsent = channelConsentByContactInfoId.get(contactInfoId);
                } else {
                    channelConsent = new PJN_Channel_Consent__c(
                        PJN_Contact_Information__c = contactInfoId,
                        PJN_Data_Use_Purpose__c = dataUsePurpose.Id,
                        PJN_Contact_Type__c = contactInfoMap.get(contactInfoId).RecordType.Name
                    );
                }
                setChannelConsent(channelConsent, consentType, dataUsePurpose);
                channelConsentByContactInfoId.put(contactInfoId, channelConsent);
            }
            upsert channelConsentByContactInfoId.values();
        } else {
            throw new PJN_ConsentException(Label.PJN_Contact_Information_Consent_DataUsePurpose_Exception);
        }

    }

    /**
     * If there is an existing channel consent for a contact information record, update the
     * effective from/to dates and the privacy consent status, if not create a new one.
     * @param  contactInfoIdsList   list of contact information records to process
     * @param  programDeveloperName program developer name
     * @param  consentType          consent type
     */
    public static List<PJN_Channel_Consent__c> buildConsentForContactInformation(List<Id> contactInfoIdsList,
                                                                        String programDeveloperName,
                                                                        String consentType) {
        Map<Id, PJN_Contact_Information__c> contactInfoMap = getContactInfoMap(contactInfoIdsList);
        Map<Id, PJN_Channel_Consent__c> channelConsentByContactInfoId = getExistingChannelConsentByContactInfoId(contactInfoIdsList);
        List<DataUsePurpose> dataUsePurposeList = getDataUsePurpose(programDeveloperName);

        if (!dataUsePurposeList.isEmpty()) {
            DataUsePurpose dataUsePurpose = dataUsePurposeList.get(0);
            PJN_Channel_Consent__c channelConsent;
            for (Id contactInfoId : contactInfoIdsList) {
                if (channelConsentByContactInfoId.containsKey(contactInfoId)) {
                    channelConsent = channelConsentByContactInfoId.get(contactInfoId);
                } else {
                    channelConsent = new PJN_Channel_Consent__c(
                        PJN_Contact_Information__c = contactInfoId,
                        PJN_Data_Use_Purpose__c = dataUsePurpose.Id,
                        PJN_Contact_Type__c = contactInfoMap.get(contactInfoId).RecordType.Name
                    );
                }
                setChannelConsent(channelConsent, consentType, dataUsePurpose);
                channelConsentByContactInfoId.put(contactInfoId, channelConsent);
            }
            return channelConsentByContactInfoId.values();
        } else {
            return new List<PJN_Channel_Consent__c>();
        }
    }

    /**
     * Build Consent Channels for all Contact Information records associated to a care plan.
     * If there is an existing channel consent for a contact information record, update the
     * effective from/to dates and the privacy consent status, if not create a new one.
     * @param  carePlanByAccountId map of care plans by account Id
     * @param  consentType          consent type
     * @return List<PJN_Channel_Consent__c>
     */
    public static List<PJN_Channel_Consent__c> buildConsentForContactInformationBatch(
                                                                        Map<Id, Case> carePlanByAccountId,
                                                                        String consentType) {

        Set<Id> accountIds = carePlanByAccountId.keySet();
        List<PJN_Contact_Information__c> contactInfoList = getContactInfoList(accountIds);
        Map<Id, PJN_Channel_Consent__c> channelConsentByContactInfoId = getExistingChannelConsentByContactInfoId(contactInfoList);

        Map<String, DataUsePurpose> dataUsePurposeMap = getDataUsePurposeByProgramDevName();

        if (dataUsePurposeMap.isEmpty()) {
            return new List<PJN_Channel_Consent__c>();
        }

        PJN_Channel_Consent__c channelConsent;
        for (PJN_Contact_Information__c contactInfo : contactInfoList) {

            Id accId = contactInfo.PJN_Account__c;
            if (!dataUsePurposeMap.containsKey(carePlanByAccountId.get(accId).PJN_Program_DeveloperName__c)) {
                continue;
            }
            DataUsePurpose dataUsePurpose = dataUsePurposeMap.get(carePlanByAccountId.get(accId).PJN_Program_DeveloperName__c);

            if (channelConsentByContactInfoId.containsKey(contactInfo.Id)) {
                channelConsent = channelConsentByContactInfoId.get(contactInfo.Id);
            } else {
                channelConsent = new PJN_Channel_Consent__c(
                    PJN_Contact_Information__c = contactInfo.Id,
                    PJN_Data_Use_Purpose__c = dataUsePurpose.Id,
                    PJN_Contact_Type__c = contactInfo.RecordType.Name
                );
            }
            setChannelConsent(channelConsent, consentType, dataUsePurpose);
            channelConsentByContactInfoId.put(contactInfo.Id, channelConsent);
        }
        return channelConsentByContactInfoId.values();
    }

    /**
     * Return List of Contact Info records
     * @param  accountIds Set of Account Ids
     * @return List<PJN_Contact_Information__c>
     */
    private static List<PJN_Contact_Information__c> getContactInfoList(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                PJN_Account__c,
                RecordType.Name
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Account__c IN :accountIds
        ];
    }


    /**
     * set channel consent effective dates and privacy consent status
     * @param  channelConsent channel consent record
     * @param  consentType    consent type
     * @param  dataUsePurpose data use purpose record
     */
    private static void setChannelConsent(PJN_Channel_Consent__c channelConsent, String consentType,
                                            DataUsePurpose dataUsePurpose) {
        if (consentType == OPT_IN) {
            Date today = System.today();
            channelConsent.PJN_Effective_From__c = today;
            channelConsent.PJN_Effective_To__c = dataUsePurpose.PJN_Effective_Months__c != null ? today.addMonths(dataUsePurpose.PJN_Effective_Months__c.intValue()) : null;
            channelConsent.PJN_Privacy_Consent_Status__c = 'Opt In';
        } else if (consentType == OPT_OUT) {
            channelConsent.PJN_Effective_From__c = null;
            channelConsent.PJN_Effective_To__c = null;
            channelConsent.PJN_Privacy_Consent_Status__c = 'Opt Out';
        }
    }

    /**
     * Get contact information recods in a map
     * @param  contactInfoIdsList contact information id list
     * @returns Map<Id, PJN_Contact_Information__c>
     */
    private static Map<Id, PJN_Contact_Information__c> getContactInfoMap(List<Id> contactInfoIdsList) {
        return new Map<Id, PJN_Contact_Information__c>(
            [SELECT RecordType.Name FROM PJN_Contact_Information__c WHERE Id IN :contactInfoIdsList]
        );
    }

    /**
     * Get all existing channel consent records for contact information records being passed by
     * contact information id.
     * @param  contactInfoIdsList contact information id list
     * @returns Map<Id, PJN_Channel_Consent__c>
     */
    private static Map<Id, PJN_Channel_Consent__c> getExistingChannelConsentByContactInfoId(List<Id> contactInfoIdsList) {
        List<PJN_Channel_Consent__c> existingChannelConsent = [
            SELECT
                Id,
                PJN_Privacy_Consent_Status__c,
                PJN_Contact_Information__c
            FROM
                PJN_Channel_Consent__c
            WHERE
                PJN_Contact_Information__c IN :contactInfoIdsList
        ];
        Map<Id, PJN_Channel_Consent__c> channelConsentByContactInfoId = new Map<Id, PJN_Channel_Consent__c>();
        for (PJN_Channel_Consent__c channelConsent : existingChannelConsent) {
            channelConsentByContactInfoId.put(channelConsent.PJN_Contact_Information__c, channelConsent);
        }
        return channelConsentByContactInfoId;
    }

    /**
     * Get all existing channel consent records for contact information records being passed by
     * contact information record.
     * @param  contactInfoList contact information records list
     * @returns Map<Id, PJN_Channel_Consent__c>
     */
    private static Map<Id, PJN_Channel_Consent__c> getExistingChannelConsentByContactInfoId(List<PJN_Contact_Information__c> contactInfoList) {
        List<Id> contactInfoIds = new List<Id>();
        for (PJN_Contact_Information__c contactInfo : contactInfoList) {
            contactInfoIds.add(contactInfo.Id);
        }
        return getExistingChannelConsentByContactInfoId(contactInfoIds);
    }

    /**
     * get Data Use Purpose record for the "Program Consent" type
     * @param  programDeveloperName program developer name
     * @returns List<DataUsePurpose>
     */
    private static List<DataUsePurpose> getDataUsePurpose(String programDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Effective_Months__c
            FROM
                DataUsePurpose
            WHERE
                Purpose.PJN_Program_DeveloperName__c = :programDeveloperName
            AND
                PJN_Type__c = 'Program Consent'
        ];
    }

    private static Map<String, DataUsePurpose> getDataUsePurposeByProgramDevName() {
        List<DataUsePurpose> dataUsePurposeList = [
            SELECT
                Id,
                PJN_Effective_Months__c,
                Purpose.PJN_Program_DeveloperName__c
            FROM
                DataUsePurpose
            WHERE
                PJN_Type__c = 'Program Consent'
        ];
        Map<String, DataUsePurpose> dataUsePurposeMap = new Map<String, DataUsePurpose>();
        for (DataUsePurpose dataUsePurposeRecord : dataUsePurposeList) {
            dataUsePurposeMap.put(dataUsePurposeRecord.Purpose.PJN_Program_DeveloperName__c, dataUsePurposeRecord);

        }
        return dataUsePurposeMap;
    }
}