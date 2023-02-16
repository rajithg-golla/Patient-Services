/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Collection of queries and shared methods used by PopulateCarePlanHdlr and CareConsentsHdlrMVN
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LeadConversionUtilityMVN {


    public static Map<Id, List<PJN_Contact_Information__c>> queryContactInformationMap(Set<Id> accountIds) { //, Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> recordTypeSettingMap) {
        Map<Id, List<PJN_Contact_Information__c>> result = new Map<Id, List<PJN_Contact_Information__c>>();

        for (PJN_Contact_Information__c contactInfo : [SELECT PJN_Account__c, PJN_Record_Type_Name__c FROM PJN_Contact_Information__c WHERE PJN_Account__c IN :accountIds]) {
            if (result.containsKey(contactInfo.PJN_Account__c)) {
                List<PJN_Contact_Information__c> currentList = result.get(contactInfo.PJN_Account__c);
                currentList.add(contactInfo);
                result.put(contactInfo.PJN_Account__c, currentList);
            } else {
                result.put(contactInfo.PJN_Account__c, new List<PJN_Contact_Information__c>{contactInfo});
            }
        }

        return result;
    }

    public static List<Case> queryCarePlans(List<Id> carePlanIds) {
        return [SELECT AccountId, Care_Plan_Template_External_ID_MVN__c, Converted_Lead_MVN__c, PJN_Program__c, Record_Type_Key_MVN__c FROM Case WHERE Id IN :carePlanIds];
    }

    public static Map<String, CareProgram> queryCareProgramMap(List<Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> recordTypeSettings) {
        Set<String> programDevNames = new Set<String>();
        for (Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt recordTypeSetting : recordTypeSettings) {
            programDevNames.add(recordTypeSetting.Care_Program_DeveloperName_MVN__c);
        }
        System.debug('#### programDevNames: ' + programDevNames);

        Map<String, CareProgram> result = new Map<String, CareProgram>();
        for (CareProgram program : [SELECT PJN_Program_DeveloperName__c FROM CareProgram WHERE PJN_Program_DeveloperName__c IN :programDevNames]) {
            result.put(program.PJN_Program_DeveloperName__c, program);
        }

        System.debug('#### programMap: ' + result);
        return result;
    }

    public static Map<Id, Lead> queryLeadMap(String soqlString, Set<String> leadIds) {
        Map<Id, Lead> result = new Map<Id, Lead>();

        System.debug('#### querying leads');
        for (Lead consumer : Database.query(soqlString)) {
            System.debug('#### lead found: ' + consumer);
            result.put(consumer.Id, consumer);
        }

        return result;
    }

    public static Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> queryRecordTypeSettingMap() {
        Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt> result = new Map<String, Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt>();
        for (Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt rtMapping : [SELECT Care_Program_DeveloperName_MVN__c, Care_Plan_Record_Type_DeveloperName_MVN__c, CarePlan_RecordType_Namespace_Prefix_MVN__c FROM Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt]) {
            result.put((rtMapping.CarePlan_RecordType_Namespace_Prefix_MVN__c == NULL ? '' : rtMapping.CarePlan_RecordType_Namespace_Prefix_MVN__c) + rtMapping.Care_Plan_Record_Type_DeveloperName_MVN__c, rtMapping);
        }
        return result;
    }

    public static List<Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt> queryFieldMappingSettings() {
        return [SELECT Care_Plan_Field_Name_MVN__c, Care_Plan_Record_Type_DeveloperName_MVN__c, Care_Plan_Record_Type_Namespace_Pref_MVN__c, Is_Active_MVN__c, Lead_Field_Name_MVN__c, Text_Value_MVN__c FROM Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt WHERE Is_Active_MVN__c = TRUE];
    }

    public static Map<Id, DataUsePurpose> queryDataUsePurposeMap(Set<Id> dataUsePurposeIds) {
        return new Map<Id, DataUsePurpose>([SELECT PJN_Effective_Months__c FROM DataUsePurpose WHERE Id IN :dataUsePurposeIds]);
    }

    public static Map<Id, DataUsePurpose> queryDataUsePurposeMapByPurpose(Set<Id> purposes) {
        Map<Id, DataUsePurpose> result = new Map<Id, DataUsePurpose>();
        for (DataUsePurpose purpose : [SELECT PJN_Effective_Months__c, PurposeId FROM DataUsePurpose WHERE PJN_Type__c = 'Program Consent' AND PurposeId IN :purposes]) {
            result.put(purpose.PurposeId, purpose);
        }
        return result;
    }

    public static Map<String, HealthCloudGA__CarePlanTemplate__c> queryTemplateMap(Set<String> templateIds) {
        Map<String, HealthCloudGA__CarePlanTemplate__c> templateMap = new Map<String, HealthCloudGA__CarePlanTemplate__c>();
        for (HealthCloudGA__CarePlanTemplate__c template : [SELECT Address_Channel_Consent_Status_MVN__c, Email_Channel_Consent_Status_MVN__c, External_ID_MVN__c, HIPAA_Consent_Data_Use_Purpose_MVN__c, Marketing_Consent_Data_Use_Purpose_MVN__c, Phone_Channel_Consent_Status_MVN__c, Program_Consent_Data_Use_Purpose_MVN__c FROM HealthCloudGA__CarePlanTemplate__c WHERE External_ID_MVN__c IN :templateIds]) {
            templateMap.put(template.External_ID_MVN__c, template);
        }
        return templateMap;
    }
}