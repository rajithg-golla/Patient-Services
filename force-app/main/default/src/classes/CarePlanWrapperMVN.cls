/**
 * @author      Mavens
 * @group       LeadMVN
 * @description A collection of records related to the CarePlan used to populate fields and records.
 */
public without sharing class CarePlanWrapperMVN {

    public Case carePlan {get; set;}
    public Lead consumer {get; set;}

    public List<PJN_Contact_Information__c> contactInformationRecords {get; set;}
    public HealthCloudGA__CarePlanTemplate__c template {get; set;}

    // Possible DataUsePurpose records
    public DataUsePurpose hipaaDUP {get; set;}
    public DataUsePurpose marketingDUP {get; set;}
    public DataUsePurpose programDUP {get; set;}
    public DataUsePurpose programConsent {get; set;}

    public CarePlanWrapperMVN(Case carePlan) {
        this.carePlan = carePlan;
    }

    public void mapCarePlanFields(Lead consumer, List<Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt> fieldMappingSettings) {
        for (Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt fieldMappingSetting : fieldMappingSettings) {
            if (hasMatchingRecordType(fieldMappingSetting) && fieldMappingSetting.Text_Value_MVN__c != NULL) {
                carePlan.put(fieldMappingSetting.Care_Plan_Field_Name_MVN__c, fieldMappingSetting.Text_Value_MVN__c);
            } else if (hasMatchingRecordType(fieldMappingSetting)) {
                carePlan.put(fieldMappingSetting.Care_Plan_Field_Name_MVN__c, consumer.get(fieldMappingSetting.Lead_Field_Name_MVN__c));
            }
        }
    }

    private Boolean hasMatchingRecordType(Lead_Convert_Care_Plan_Field_Mapping_MVN__mdt fieldMappingSetting) {
        return carePlan.Record_Type_Key_MVN__c == ((fieldMappingSetting.Care_Plan_Record_Type_Namespace_Pref_MVN__c == NULL ? '' : fieldMappingSetting.Care_Plan_Record_Type_Namespace_Pref_MVN__c ) + fieldMappingSetting.Care_Plan_Record_Type_DeveloperName_MVN__c);
    }
}