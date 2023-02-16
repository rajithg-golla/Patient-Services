/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMAffiliation Affiliation DataLake Object
 */
public with sharing class MVN_DataLakeCMAffiliation {

    /**
     * DataLake Affiliation objects
     */
    public String hco_hcp_affiliation_id;
    public String hco_hcp_affiliation_status;
    public String hco_hcp_affiliation_hco_id;
    public String hco_hcp_affiliation_hcp_id;

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `PJN_Affiliation__c`
     */
    public PJN_Affiliation__c getSFDCRecord() {
        return new PJN_Affiliation__c(
            PJN_Child_Account__r = new Account(
                HealthCloudGA__SourceSystemId__c = this.hco_hcp_affiliation_hcp_id
            ),
            PJN_Parent_Account__r = new Account(
                HealthCloudGA__SourceSystemId__c = this.hco_hcp_affiliation_hco_id
            ),
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getCompleteStatusFromMapped(this.hco_hcp_affiliation_status),
            MVN_External_Id__c = this.hco_hcp_affiliation_id
        );
    }
}