/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMPhone Phone DataLake Object
 */
public with sharing class MVN_DataLakeCMPhone {

    /**
     * DataLake HCP Phone object
     */
    public String hcp_phone_id;
    public String hcp_phone_standard_phone_num;
    public String hcp_phone_valid_status;
    public String hcp_phone_type_cd;
    public String hcp_phone_hcp_id;

    /**
     * DataLake HCO Phone object
     */
    public String hco_phone_id;
    public String hco_phone_standard_phone_num;
    public String hco_phone_valid_status;
    public String hco_phone_type_cd;
    public String hco_phone_hco_id;

    /**
     * DataLake Record Type Mapping to SFDC Record Type
     */
    private static final Map<String, String> RECORD_TYPE_MAPPING = new Map<String, String> {
        'fx' => 'PJN_Fax',
        'per_fax' => 'PJN_Fax',
        'of' => 'PJN_Fax',
        'per_phone' => 'PJN_Phone',
        'mb' => 'PJN_Phone',
        'op' => 'PJN_Phone',
        'personmobilephone' => 'PJN_Phone',
        'ph' => 'PJN_Phone'
    };

    /**
     * DataLake Type Mapping to SFDC Type
     */
    private static final Map<String, String> TYPE_MAPPING = new Map<String, String> {
        'fx' => 'Business',
        'per_fax' => 'Home',
        'of' => 'Business',
        'mb' => 'Business',
        'per_phone' => 'Home',
        'op' => 'Business',
        'personmobilephone' => 'Mobile',
        'ph' => 'Home'
    };

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * The Datalake type and isPersonSearch define if this returns a phone or fax Contact Information record
     * @param isPersonSearch    Defines if it is a Person or Business Account Search
     * @return  `PJN_Contact_Information__c`
     */
    public PJN_Contact_Information__c getSFDCRecord(Boolean isPersonSearch) {
        String phoneType = isPersonSearch ? this.hcp_phone_type_cd : this.hco_phone_type_cd;
        String recordTypeDevName = RECORD_TYPE_MAPPING.get(phoneType.toLowerCase());
        String status = isPersonSearch ? this.hcp_phone_valid_status : this.hco_phone_valid_status;
        PJN_Contact_Information__c ci = new PJN_Contact_Information__c (
            RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId(),
            PJN_Type__c = TYPE_MAPPING.get(phoneType.toLowerCase()),
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(status),
            PJN_External_Id__c = isPersonSearch ? this.hcp_phone_id : this.hco_phone_id
        );
        String phoneNumber = isPersonSearch ? this.hcp_phone_standard_phone_num : this.hco_phone_standard_phone_num;
        if (recordTypeDevName == 'PJN_Fax') {
            ci.PJN_Fax__c = phoneNumber;
        } else if (recordTypeDevName == 'PJN_Phone') {
            ci.PJN_Phone__c = phoneNumber;
        }
        return ci;
    }

}