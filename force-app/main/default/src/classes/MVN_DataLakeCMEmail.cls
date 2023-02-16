/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMEmail Email DataLake Object
 */
public with sharing class MVN_DataLakeCMEmail {

    /**
     * DataLake HCP Email object
     */
    public String hcp_email_id;
    public String hcp_email_email_value;
    public String hcp_email_valid_status;
    public String hcp_email_hcp_id;

    /**
     * DataLake HCO Email object
     */
    public String hco_email_id;
    public String hco_email_standard_email;
    public String hco_email_valid_status;
    public String hco_email_hco_id;

    /**
     * Search Email Populated Fields
     */
    private Map<String, Object> reqEmailPopulatedFields;

    /**
     * Constructor to get all search fields and store into this wrapper to build they query
     * @param reqEmailPopulatedFields   Email Search populated field
     */
    public MVN_DataLakeCMEmail(Map<String, Object> reqEmailPopulatedFields) {
        this.reqEmailPopulatedFields = reqEmailPopulatedFields;
        if (this.reqEmailPopulatedFields == null || this.reqEmailPopulatedFields.isEmpty()) {
            return;
        }
        this.hcp_email_id = MVN_DataLakeCMSearchUtil.getStringValue(this.reqEmailPopulatedFields, 'id');
        this.hcp_email_email_value = MVN_DataLakeCMSearchUtil.getStringValue(this.reqEmailPopulatedFields, 'PJN_Email__c');
        this.hcp_email_valid_status = 'Y';
    }

    /**
     * Get Email Search filter using the populated fields
     * This Search filter is configured to work with Person Account only.
     * @return  `String`
     */
    public String getSearchFilters() {
        String filters = '';
        if (String.isNotBlank(this.hcp_email_email_value)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hcp_email_email_value', this.hcp_email_email_value);
        }
        if (String.isNotBlank(filters)) {
            MVN_DataLakeCMSearchHdlr.hasSearchFilter = true;
            filters += 'Upper(hcp_email_valid_status) = \'' + this.hcp_email_valid_status + '\' AND ';
        }
        return filters.substringBeforeLast(' AND ');
    }

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @param isPersonSearch    Defines if it is a Person or Business account search
     * @return  `PJN_Contact_Information__c`
     */
    public PJN_Contact_Information__c getSFDCRecord(Boolean isPersonSearch) {
        String emailValidStatus = isPersonSearch ? this.hcp_email_valid_status : this.hco_email_valid_status;
        return new PJN_Contact_Information__c (
            RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
            PJN_Email__c = isPersonSearch ? this.hcp_email_email_value : this.hco_email_standard_email,
            PJN_External_ID__c = isPersonSearch ? this.hcp_email_id : this.hco_email_id,
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(emailValidStatus)
        );
    }
}