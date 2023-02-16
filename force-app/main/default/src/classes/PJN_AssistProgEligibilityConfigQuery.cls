/**
 * @author      Mavens
 * @date        10/2020
 * @description Query class to access Assistance Program Eligibility Configurations
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_AssistProgEligibilityConfigQuery {

    public PJN_Assistance_Prog_Eligibility_Config__mdt getConfigurationByDevName(String devName) {
        return [
            SELECT PJN_Clearing_House_Class__c
            FROM PJN_Assistance_Prog_Eligibility_Config__mdt
            WHERE DeveloperName = :devName
            LIMIT 1
        ];
    }
}