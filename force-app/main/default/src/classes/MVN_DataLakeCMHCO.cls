/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMHCO HCO DataLake Object
 */
public with sharing class MVN_DataLakeCMHCO {

    /**
     * Datalake HCO objects
     */
    public String hco_id;
    public String hco_name;
    public String hco_type_cd;
    public String hco_status_type_cd;

    /**
     * Search HCO Populated Fields
     */
    private Map<String, Object> reqAccountPopulatedFields;

    /**
     * Constructor to get all search fields and store into this wrapper to build they query
     * @param reqAccountPopulatedFields HCO Search populated fields
     */
    public MVN_DataLakeCMHCO(Map<String, Object> reqAccountPopulatedFields) {
        this.reqAccountPopulatedFields = reqAccountPopulatedFields;
        if (this.reqAccountPopulatedFields == null || this.reqAccountPopulatedFields.isEmpty()) {
            return;
        }
        this.hco_id = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'id');
        this.hco_name = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAccountPopulatedFields, 'Name');
        this.hco_status_type_cd = 'A';
    }

    /**
     * Get HCO Search filter using the populated fields
     * @return  `String`
     */
    public String getSearchFilters() {
        String filters = '';
        if (String.isNotBlank(this.hco_name)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('hco_name', this.hco_name);
        }
        if (String.isNotBlank(filters)) {
            MVN_DataLakeCMSearchHdlr.hasSearchFilter = true;
        }
        filters += 'Upper(hco_status_type_cd) = \'' + this.hco_status_type_cd + '\' AND ';
        return filters.substringBeforeLast(' AND ');
    }

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `Account`
     */
    public Account getSFDCRecord() {
        return new Account (
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId(),
            Name = this.hco_name,
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(this.hco_status_type_cd),
            HealthCloudGA__SourceSystemId__c = this.hco_id
        );
    }
}