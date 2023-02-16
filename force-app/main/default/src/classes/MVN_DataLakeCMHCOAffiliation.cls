/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMHCOAffiliation HCO Affiliation DataLake Object
 */
public with sharing class MVN_DataLakeCMHCOAffiliation {

    /**
     * DataLake HCO Affiliation objects
     */
    public String hco_hco_affiliation_id;
    public String hco_hco_affiliation_provider;
    public String hco_hco_affiliation_primary_ind;
    public String hco_hco_affiliation_type_cd;
    public String hco_hco_affiliation_type_desc;
    public String hco_hco_affiliation_hco_id_parent;
    public String hco_hco_affiliation_hco_id_child;
    public String hco_hco_affiliation_status;

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `PJN_Affiliation__c`
     */
    public PJN_Affiliation__c getSFDCRecord() {
        return new PJN_Affiliation__c(
            PJN_Child_Account__r = new Account(
                HealthCloudGA__SourceSystemId__c = this.hco_hco_affiliation_hco_id_child
            ),
            PJN_Parent_Account__r = new Account(
                HealthCloudGA__SourceSystemId__c = this.hco_hco_affiliation_hco_id_parent
            ),
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getCompleteStatusFromMapped(this.hco_hco_affiliation_status),
            MVN_External_Id__c = this.hco_hco_affiliation_id
        );
    }
}