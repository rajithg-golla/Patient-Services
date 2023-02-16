/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Populating Care Plan from the Lead conversion flow.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PopulateCarePlanHdlrMVN {

    // List of all Care Plan Wrappers
    private static List<CarePlanWrapperMVN> wrappers;

    // record type setting to see if current careplan is eligible for marketing
    private static Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> recordTypeSettingMap;

    // custom metadata for populating care plan fields
    private static List<Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt> fieldMappingSettings;

    // has lead fields
    private static Boolean hasLeadFieldMappings;

    @InvocableMethod(
        label='Populate Care Plans' 
        description='Populate Care Plans based on Field Mappings in Custom Metadata.' 
        category='Lead'
    )
    public static void populateCarePlans(List<Id> carePlanIds) {

        // collect record type custom metadata
        recordTypeSettingMap = LeadConversionUtilityMVN.queryRecordTypeSettingMap();

        // build initial care plan wrappers
        Map<String, CareProgram> programMap = LeadConversionUtilityMVN.queryCareProgramMap(recordTypeSettingMap.values());
        setCarePlanWrappers(carePlanIds);

        // collect field mappings and leads and populate the care plan in the wrapper.
        processLeadToCarePlanFieldMappings();

        // collect care plans for update and update
        performDML();
    }

    /**
     * Collect leads and assign to wrappers
     */
    private static void processLeadToCarePlanFieldMappings() {

        Set<String> leadIds = getLeadIds();
        hasLeadFieldMappings = false; // set hasLeadFieldMappings to false, should only be set to true when it's found
        fieldMappingSettings = LeadConversionUtilityMVN.queryFieldMappingSettings();
        Map<Id, Lead> leadMap = getLeadMap(leadIds);

        // Take the lead and field wrappers and passes it to the wrappers to populate the wrappers.
        populateCarePlanFieldsOnWrappers(leadMap);
    }

    /**
     * Perform all updates and inserts
     */
    private static void performDML() {
        // collect records for insertion
        List<Case> carePlans = getCarePlansForUpdate();

        // updates
        update carePlans;
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

            if (wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c != NULL) {
                wrapper.marketingDUP = dataUsePurposeMap.get(wrapper.template.Marketing_Consent_Data_Use_Purpose_MVN__c);
            }

            if (wrapper.template.Program_Consent_Data_Use_Purpose_MVN__c != NULL) {
                wrapper.programDUP = dataUsePurposeMap.get(wrapper.template.Program_Consent_Data_Use_Purpose_MVN__c);
            }
        }
    }

    /**
     * Take the lead and field wrappers and passes it to the wrappers to populate the wrappers.
     * @param leadMap 
     */
    private static void populateCarePlanFieldsOnWrappers(Map<Id, Lead> leadMap) {
        for (CarePlanWrapperMVN wrapper : wrappers) {
            if (leadMap.containsKey(wrapper.carePlan.Converted_Lead_MVN__c)) {
                wrapper.mapCarePlanFields(leadMap.get(wrapper.carePlan.Converted_Lead_MVN__c), fieldMappingSettings);
            } else {
                wrapper.mapCarePlanFields(new Lead(), fieldMappingSettings);
            }
        }
    }

    private static PJN_Channel_Consent__c buildChannelConsent(PJN_Contact_Information__c contactInfo, DataUsePurpose dup) {
        Date today = Date.today();

        return new PJN_Channel_Consent__c(
            PJN_Contact_Information__c = contactInfo.Id,
            PJN_Data_Use_Purpose__c = dup.Id,
            PJN_Effective_From__c = today,
            PJN_Effective_To__c = today.addMonths((Integer) dup.PJN_Effective_Months__c),
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

    private static List<Case> getCarePlansForUpdate() {
        List<Case> result = new List<Case>();

        for (CarePlanWrapperMVN wrapper : wrappers) {
            result.add(wrapper.carePlan);
        }

        return result;
    }

    private static String getFieldMappingSoqlString() {
        String soqlString = 'SELECT ConvertedAccountId, HealthCloudGA__CarePlanRecordTypeNamespace__c, HealthCloudGA__CarePlanRecordTypeName__c';
        for (Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt fieldMapping : fieldMappingSettings) {
            if (hasLeadFieldMapping(fieldMapping)) {
                hasLeadFieldMappings = true;
                soqlString += ', ' + fieldMapping.Lead_Field_Name_MVN__c;
            }
        }
        soqlString += ' FROM Lead WHERE Id IN :leadIds ORDER BY CreatedDate';

        return soqlString;
    }

    private static Set<String> getLeadIds() {
        Set<String> leadIds = new Set<String>();

        for (CarePlanWrapperMVN wrapper : wrappers) {
            leadIds.add(wrapper.carePlan.Converted_Lead_MVN__c);
        }

        return leadIds;
    }

    private static Map<Id, Lead> getLeadMap(Set<String> leadIds) {
        Map<Id, Lead> result = new Map<Id, Lead>();

        if (hasLeadFieldMappings) {
            return result;
        }

        return LeadConversionUtilityMVN.queryLeadMap(getFieldMappingSoqlString(), leadIds);
    }

    public static List<CarePlanWrapperMVN> setCarePlanWrappers(List<Id> carePlanIds) {
        Map<String, CareProgram> programMap = LeadConversionUtilityMVN.queryCareProgramMap(recordTypeSettingMap.values());
        wrappers = new List<CarePlanWrapperMVN>();
        for (Case carePlan : LeadConversionUtilityMVN.queryCarePlans(carePlanIds)) {
            Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt recordTypeSetting;
            if (recordTypeSettingMap.containsKey(carePlan.Record_Type_Key_MVN__c)) {
                recordTypeSetting = recordTypeSettingMap.get(carePlan.Record_Type_Key_MVN__c);
                if (programMap.containsKey(recordTypeSetting.Care_Program_DeveloperName_MVN__c)) {
                    CareProgram program = programMap.get(recordTypeSetting.Care_Program_DeveloperName_MVN__c);
                    carePlan.PJN_Program__c = program.Id;
                }
            }
            wrappers.add(new CarePlanWrapperMVN(carePlan));
        }

        return wrappers;
    }

    private static Boolean hasLeadFieldMapping(Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt fieldMapping) {
        return fieldMapping.Is_Active_MVN__c && fieldMapping.Text_Value_MVN__c == NULL;
    }
}