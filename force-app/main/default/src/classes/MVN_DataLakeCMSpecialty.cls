/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMSpecialty Specialty DataLake Object
 */
public with sharing class MVN_DataLakeCMSpecialty {

    /**
     * DataLake HCP Specialty object
     */
    public String hcp_spec_id;
    public String hcp_spec_type;
    public String hcp_spec_hcp_id;

    /**
     * Specialty Type Mapping
     */
    private static Map<String, String> SPECIALTY_TYPE_MAPPING = new Map<String, String> {
        'physician assistant' => 'Internal Medicine',
        'osteopathic physician and surgeon - specialty unknown' => 'Internal Medicine',
        'graduate osteopathic trainee - otolaryngology and facial plastic surg' => 'Internal Medicine',
        'no call specialty' => 'Internal Medicine',
        'do - otolaryngology - plastic surgery within the head & neck' => 'Internal Medicine',
        'physician - otolaryn & facial plastic surgery - head and neck surgery' => 'Internal Medicine',
        'unspecified' => 'Internal Medicine',
        'otolaryngology' => 'Internal Medicine'
    };

    /**
     * Get the Account record with the specialty populated and mapped
     * @param thisAccount   SFDC Account record
     * @return  `Account`
     */
    public Account getSFDCRecord(Account thisAccount) {
        thisAccount.PJN_Specialty__c = MVN_DataLakeCMSearchUtil.getStringValueMappedWithDefault(this.hcp_spec_type, SPECIALTY_TYPE_MAPPING, null);
        return thisAccount;
    }
}