/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMHCP HCP DataLake Object
 */
public with sharing class MVN_DataLakeCMHCP {

    /**
     * Datalake HCP objects
     */
    public String hcp_id;
    public String hcp_salutation;
    public String hcp_first_name;
    public String hcp_middle_name;
    public String hcp_last_name;
    public String hcp_suffix;
    public String hcp_gender;
    public Date hcp_birth_date;
    public String hcp_npi_id;
    public String hcp_dea_num;
    public String hcp_active_flag;
    public String hcp_type_cd;
    public String hcp_status_type_cd;

    /**
     * Search HCP Populated Fields
     */
    private Map<String, Object> reqAccountPopulatedFields;

    /**
     * Gender Mappings from/to Datalake
     */
    private static final Map<String, String> GENDER_MAPPING = new Map<String, String> {
        'male' => 'M',
        'female' => 'F',
        'm' => 'Male',
        'f' => 'Female'
    };

    /**
     * Record Type Mappings from/to Datalake
     */
    private static final Map<String, String> RECORD_TYPE_MAPPING = new Map<String, String> {
        'pjn_physician' => 'PRES',
        'pjn_staff' => 'NON-PRES',
        'pres' => 'PJN_Physician',
        'non-pres' => 'PJN_Staff'
    };

    /**
     * Constructor to get all search fields and store into this wrapper to build they query
     * @param reqAccountPopulatedFields HCP Search populated fields
     */
    public MVN_DataLakeCMHCP(Map<String, Object> reqAccountPopulatedFields) {
        this.reqAccountPopulatedFields = reqAccountPopulatedFields;
        if (this.reqAccountPopulatedFields == null || this.reqAccountPopulatedFields.isEmpty()) {
            return;
        }
        this.hcp_id = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'id');
        this.hcp_salutation = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'Salutation');
        this.hcp_first_name = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'FirstName');
        this.hcp_middle_name = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'MiddleName');
        this.hcp_last_name = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'LastName');
        this.hcp_gender = MVN_DataLakeCMSearchUtil.getStringValueMappedWithDefault(
            MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'HealthCloudGA__Gender__pc'),
            GENDER_MAPPING,
            null
        );
        this.hcp_suffix = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'Suffix');
        this.hcp_birth_date = MVN_DataLakeCMSearchUtil.getDateValue(this.reqAccountPopulatedFields, 'MVN_Birthdate__c');
        this.hcp_npi_id = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'PJN_NPI__c');
        this.hcp_dea_num = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'PJN_DEA__c');
        this.hcp_status_type_cd = 'A';
        String recordTypeValue = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'RecordTypeId');
        if (String.isNotBlank(recordTypeValue)) {
            recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosById().get(recordTypeValue).getDeveloperName();
        }
        this.hcp_type_cd = MVN_DataLakeCMSearchUtil.getStringValueMappedWithDefault(recordTypeValue, RECORD_TYPE_MAPPING, null);
    }

    /**
     * Get HCP Search filter using the populated fields
     * @return  `String`
     */
    public String getSearchFilters() {
        String filters = '';
        if (String.isNotBlank(this.hcp_first_name)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hcp_first_name', this.hcp_first_name);
        }
        if (String.isNotBlank(this.hcp_last_name)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hcp_last_name', this.hcp_last_name);
        }
        if (String.isNotBlank(this.hcp_npi_id)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hcp_npi_id', this.hcp_npi_id);
        }
        if (String.isNotBlank(filters)) {
            MVN_DataLakeCMSearchHdlr.hasSearchFilter = true;
        }
        if (String.isNotBlank(this.hcp_type_cd)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hcp_type_cd', this.hcp_type_cd);
        }
        filters += 'Upper(hcp_status_type_cd) = \'' + this.hcp_status_type_cd + '\' AND ';
        return filters.substringBeforeLast(' AND ');
    }

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `Account`
     */
    public Account getSFDCRecord() {
        String recordTypeDevName = MVN_DataLakeCMSearchUtil.getStringValueMappedWithDefault(this.hcp_type_cd, RECORD_TYPE_MAPPING, 'PJN_Physician');
        return new Account (
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId(),
            FirstName = this.hcp_first_name,
            LastName = this.hcp_last_name,
            MiddleName = this.hcp_middle_name,
            Salutation = this.hcp_salutation,
            HealthCloudGA__Gender__pc = MVN_DataLakeCMSearchUtil.getStringValueMappedWithDefault(this.hcp_gender, GENDER_MAPPING, null),
            Suffix = this.hcp_suffix,
            MVN_Birthdate__c = this.hcp_birth_date,
            PJN_NPI__c = this.hcp_npi_id,
            PJN_DEA__c = this.hcp_dea_num,
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(this.hcp_active_flag),
            HealthCloudGA__SourceSystemId__c = this.hcp_id
        );
    }
}