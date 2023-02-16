/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMLicense License DataLake Object
 */
public with sharing class MVN_DataLakeCMLicense {

    /**
     * Datalake HCP License objects
     */
    public String hcp_license_id;
    public String hcp_license_state_license_num;
    public Date hcp_license_expiration_date;
    public String hcp_license_state_cd;
    public String hcp_license_status;
    public String hcp_license_hcp_id;

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `PJN_License__c`
     */
    public PJN_License__c getSFDCRecord() {
        return new PJN_License__c(
            RecordTypeId = Schema.SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get('PJN_State_License_Number').getRecordTypeId(),
            MVN_External_Id__c = this.hcp_license_id,
            Name = this.hcp_license_state_license_num,
            PJN_Expiration_Date__c = this.hcp_license_expiration_date,
            PJN_Licensing_Authority__c = this.hcp_license_state_cd,
            PJN_Type__c = 'STATE',
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(this.hcp_license_status)
        );
    }
}