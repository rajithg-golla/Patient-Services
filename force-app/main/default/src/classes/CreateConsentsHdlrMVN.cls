/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Create Consent records.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CreateConsentsHdlrMVN {

    // List of all Care Plan Wrappers
    private static List<CarePlanWrapperMVN> wrappers;

    // record type setting to see if current careplan is eligible for marketing
    // private static Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> recordTypeSettingMap;

    @InvocableMethod(
        label='Create Consents' 
        description='Create Consents from Lead.' 
        category='Lead'
    )
    public static void createConsents(List<Id> carePlanIds) {
        System.debug('#### Create Consents class called.');

        // collect record type custom metadata
        // recordTypeSettingMap = LeadConversionUtilityMVN.queryRecordTypeSettingMap();
        // System.debug('#### recordTypeSettingMap:' + recordTypeSettingMap);
        // System.debug('#### recordTypeSettingMap.keySet:' + recordTypeSettingMap.keySet());

        // build initial care plan wrappers
        System.debug('#### carePlanIds: ' + carePlanIds);
        setCarePlanWrappers(carePlanIds);

        // collect contact information and assign to wrapper
        collectAccountsAndContactInformation();

        // collect data use purposes for channel consents
        collectContactInfoDataUsePurposes();

        // create a External_ID_MVN__c -> template map, assign templates to wrappers.
        Map<String, HealthCloudGA__CarePlanTemplate__c> templateMap = processTemplates();

        // collect data use purposes that are in templates and assign to wrappers
        processDataUsePurposes(templateMap);

        // collect consents and channel consents for insert
        performDML();
    }

    /**
     * Collect contact information and assign to wrapper
     */
    private static void collectAccountsAndContactInformation() {
        Set<Id> accountIds = getAccountIds();
        System.debug('#### accountIds: ' + accountIds);
        Map<Id, List<PJN_Contact_Information__c>> contactInformationMap = LeadConversionUtilityMVN.queryContactInformationMap(accountIds); //, recordTypeSettingMap);
        addContactInformationToWrappers(contactInformationMap);
    }

    /**
     * Collect DataUsePurpose records and assign to wrappers.
     */
    private static void collectContactInfoDataUsePurposes() {
        Set<Id> programIds = new Set<Id>();
        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (wrapper.carePlan.PJN_Program__c != NULL) {
                programIds.add(wrapper.carePlan.PJN_Program__c);
            }
        }

        Map<Id, DataUsePurpose> dataUsePurposeMap = LeadConversionUtilityMVN.queryDataUsePurposeMapByPurpose(programIds);

        for (CarePlanWrapperMVN wrapper : wrappers) {
            wrapper.programConsent = dataUsePurposeMap.get(wrapper.carePlan.PJN_Program__c);
        }
    }

    /**
     * Collect templates and assign to wrappers
     * @return  `Map<String, HealthCloudGA__CarePlanTemplate__c>`
     */
    private static Map<String, HealthCloudGA__CarePlanTemplate__c> processTemplates() {
        Set<String> templateIds = getTemplateIdsFromWrappers();
        System.debug('#### templateIds: ' + templateIds);
        Map<String, HealthCloudGA__CarePlanTemplate__c> templateMap = LeadConversionUtilityMVN.queryTemplateMap(templateIds);
        System.debug('#### templateMap KeySet: ' + templateMap.keySet());
        System.debug('#### templateMap: ' + templateMap);
        addTemplatesToWrappers(templateMap);
        return templateMap;
    }

    /**
     * Collect data use purposes and set to wrappers.
     * @param templateMap 
     */
    private static void processDataUsePurposes(Map<String, HealthCloudGA__CarePlanTemplate__c> templateMap) {
        Set<Id> dataUsePurposeIds = getDataUsePurposeIds(templateMap.values());
        Map<Id, DataUsePurpose> dataUsePurposeMap = LeadConversionUtilityMVN.queryDataUsePurposeMap(dataUsePurposeIds);
        System.debug('#### dataUsePurposeMap: ' + dataUsePurposeMap.size());
        addDataUsePurposes(dataUsePurposeMap);
    }

    /**
     * Perform all updates and inserts
     */
    private static void performDML() {
        // collect records for insertion
        List<PJN_Contact_Point_Type_Consent__c> consents = getConsentsForInsert();
        System.debug('#### consents: ' + consents.size());
        System.debug('#### consents: ' + consents);
        List<PJN_Channel_Consent__c> channelConsents = getChannelConsentsForInsert();
        System.debug('#### channel consents: ' + channelConsents.size());
        System.debug('#### channel consents: ' + channelConsents);

        // insert consents
        insert channelConsents;
        insert consents;
    }

    /**
     * Assign the collected Contact Information to wrappers.
     * @param contactInformationMap 
     */
    private static void addContactInformationToWrappers(Map<Id, List<PJN_Contact_Information__c>> contactInformationMap) {
        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (hasAccountKeyInContactInfoMap(wrapper, contactInformationMap)) {
                wrapper.contactInformationRecords = contactInformationMap.get(wrapper.carePlan.AccountId);
            }
        }
    }

    /**
     * Assign Data Use Purpose records to the proper variables in the wrappers.
     * @param dataUsePurposeMap 
     */
    private static void addDataUsePurposes(Map<Id, DataUsePurpose> dataUsePurposeMap) {
        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (wrapper.template.HIPAA_Consent_Data_Use_Purpose_MVN__c != NULL) {
                wrapper.hipaaDUP = dataUsePurposeMap.get(wrapper.template.HIPAA_Consent_Data_Use_Purpose_MVN__c);
            }

            System.debug('#### wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c != NULL: ' + (wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c != NULL));
            if (wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c != NULL) {
                wrapper.marketingDUP = dataUsePurposeMap.get(wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c);
                System.debug('#### dataUsePurposeMap keys: ' + dataUsePurposeMap.keySet());
            }

            if (wrapper.template.Program_Consent_Data_Use_Purpose_MVN__c != NULL) {
                wrapper.programDUP = dataUsePurposeMap.get(wrapper.template.Program_Consent_Data_Use_Purpose_MVN__c);
            }
        }
    }

    private static void addTemplatesToWrappers(Map<String, HealthCloudGA__CarePlanTemplate__c> templateMap) {
        for (CarePlanWrapperMVN wrapper : wrappers) {
            wrapper.template = templateMap.get(wrapper.carePlan.Care_Plan_Template_External_ID_MVN__c);
        }
    }

    private static PJN_Channel_Consent__c buildChannelConsent(PJN_Contact_Information__c contactInfo, DataUsePurpose dup, String status) {

        PJN_Channel_Consent__c result = new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = contactInfo.Id,
            PJN_Data_Use_Purpose__c = dup.Id,
            PJN_Contact_Type__c = contactInfo.PJN_Record_Type_Name__c,
            PJN_Privacy_Consent_Status__c = status
        );

        Date today = Date.today();

        if (status == 'Opt In') {
            result.PJN_Effective_From__c = today;
            result.PJN_Effective_To__c = today.addMonths((Integer) dup.PJN_Effective_Months__c);
        }

        return result;
    }

    private static PJN_Contact_Point_Type_Consent__c buildConsent(CarePlanWrapperMVN wrapper, DataUsePurpose dup) {
        Date today = Date.today();

        return new PJN_Contact_Point_Type_Consent__c(
            PJN_Care_Plan__c = wrapper.carePlan.Id,
            PJN_Data_Use_Purpose__c = dup.Id,
            PJN_Effective_From__c = today,
            PJN_Effective_To__c = today.addMonths((Integer) dup.PJN_Effective_Months__c),
            PJN_Patient__c = wrapper.carePlan.AccountId,
            PJN_Privacy_Consent_Status__c = 'Opt In'
        );
    }


    private static Set<Id> getAccountIds() {
        Set<Id> result = new Set<Id>();
        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (wrapper.carePlan.AccountId != NULL) {
                result.add(wrapper.carePlan.AccountId);
            }
        }
        return result;
    }

    private static List<Case> getCasesForUpdate() {
        List<Case> result = new List<Case>();

        for (CarePlanWrapperMVN wrapper : wrappers) {
            result.add(wrapper.carePlan);
        }

        return result;
    }

    private static List<PJN_Channel_Consent__c> getChannelConsentsForInsert() {
        List<PJN_Channel_Consent__c> result = new List<PJN_Channel_Consent__c>();

        for (CarePlanWrapperMVN wrapper : wrappers) {
            System.debug('#### hasProgramConsentAndContactInfo(): ' + hasProgramConsentAndContactInfo(wrapper));
            if (hasProgramConsentAndContactInfo(wrapper)) {
                result.addAll(getChannelConsentsFromWrapper(wrapper));
            }
        }

        return result;
    }

    private static List<PJN_Channel_Consent__c> getChannelConsentsFromWrapper(CarePlanWrapperMVN wrapper) {
        List<PJN_Channel_Consent__c> result = new List<PJN_Channel_Consent__c>();
        for (PJN_Contact_Information__c contactInformationRecord : wrapper.ContactInformationRecords) {
            
            System.debug('#### contactInformationRecord: ' + contactInformationRecord);
            System.debug('#### contactInformationRecord.PJN_Record_Type_Name__c: ' + contactInformationRecord.PJN_Record_Type_Name__c);
            if (isEligibleForChannelConsent(wrapper, wrapper.template.Email_Channel_Consent_Status_MVN__c, contactInformationRecord.PJN_Record_Type_Name__c, 'Email')) {
                result.add(buildChannelConsent(contactInformationRecord, wrapper.programConsent, wrapper.template.Email_Channel_Consent_Status_MVN__c));

            } else if (isEligibleForChannelConsent(wrapper, wrapper.template.Address_Channel_Consent_Status_MVN__c, contactInformationRecord.PJN_Record_Type_Name__c, 'Address')) { 
                result.add(buildChannelConsent(contactInformationRecord, wrapper.programConsent, wrapper.template.Address_Channel_Consent_Status_MVN__c));

            } else if (isEligibleForChannelConsent(wrapper, wrapper.template.Phone_Channel_Consent_Status_MVN__c, contactInformationRecord.PJN_Record_Type_Name__c, 'Phone')) { 
                result.add(buildChannelConsent(contactInformationRecord, wrapper.programConsent, wrapper.template.Phone_Channel_Consent_Status_MVN__c));
            }
        }
        return result;
    }

    private static List<PJN_Contact_Point_Type_Consent__c> getConsentsForInsert() {
        List<PJN_Contact_Point_Type_Consent__c> result = new List<PJN_Contact_Point_Type_Consent__c>();

        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (wrapper.hipaaDUP != NULL) {
                result.add(buildConsent(wrapper, wrapper.hipaaDUP));
            }

            if (wrapper.marketingDUP != NULL) {
                result.add(buildConsent(wrapper, wrapper.marketingDUP));
            }

            if (wrapper.programDUP != NULL) {
                result.add(buildConsent(wrapper, wrapper.programDUP));
            }
        }

        return result;
    }

    private static Set<Id> getDataUsePurposeIds(List<HealthCloudGA__CarePlanTemplate__c> templates) {
        Set<Id> result = new Set<Id>();

        for (HealthCloudGA__CarePlanTemplate__c template : templates) {
            result.addAll(getDataUsePurposeIdsFromTemplate(template));
        }

        return result;
    }

    private static Set<Id> getDataUsePurposeIdsFromTemplate(HealthCloudGA__CarePlanTemplate__c template) {
        Set<Id> result = new Set<Id>();

        if (template.HIPAA_Consent_Data_Use_Purpose_MVN__c != NULL) {
            result.add(template.HIPAA_Consent_Data_Use_Purpose_MVN__c);
        }

        if (template.Marketing_Consent_Data_Use_Purpose_MVN__c != NULL) {
            result.add(template.Marketing_Consent_Data_Use_Purpose_MVN__c);
        }

        if (template.Program_Consent_Data_Use_Purpose_MVN__c != NULL) {
            result.add(template.Program_Consent_Data_Use_Purpose_MVN__c);
        }

        return result;
    }

    private static Set<String> getTemplateIdsFromWrappers() {
        Set<String> result = new Set<String>();
        for (CarePlanWrapperMVN wrapper : wrappers) {
            result.add(wrapper.carePlan.Care_Plan_Template_External_ID_MVN__c);
        }

        return result;
    }

    public static List<CarePlanWrapperMVN> setCarePlanWrappers(List<Id> carePlanIds) {
        wrappers = new List<CarePlanWrapperMVN>();
        for (Case carePlan : LeadConversionUtilityMVN.queryCarePlans(carePlanIds)) {
            wrappers.add(new CarePlanWrapperMVN(carePlan));
        }

        return wrappers;
    }

    private static Boolean hasAccountKeyInContactInfoMap(CarePlanWrapperMVN wrapper, Map<Id, List<PJN_Contact_Information__c>> contactInformationMap) {
        return wrapper.carePlan.AccountId != NULL && contactInformationMap.containsKey(wrapper.carePlan.AccountId);
    }

    private static Boolean hasLeadFieldMapping(Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt fieldMapping) {
        return fieldMapping.Is_Active_MVN__c && fieldMapping.Text_Value_MVN__c == NULL;
    }


    private static Boolean hasProgramConsentAndContactInfo(CarePlanWrapperMVN wrapper) {
        System.debug('##### wrapper.programConsent != NULL: ' + (wrapper.programConsent != NULL));
        System.debug('##### wrapper.ContactInformationRecords != NULL: ' + (wrapper.ContactInformationRecords != NULL));
        return wrapper.programConsent != NULL && wrapper.ContactInformationRecords != NULL;
    }
    private static Boolean isEligibleForChannelConsent(CarePlanWrapperMVN wrapper, String templateStatus, String recordType, String expectedRecordType) { // NOPMD - Sadly necessary to have long param list.
        return (
            wrapper != NULL &&
            wrapper.programConsent != NULL && 
            templateStatus != NULL && 
            templateStatus != 'Not Given' && 
            recordType == expectedRecordType
        );
    }
}