/**
 * @author      Mavens
 * @date        11/2020
 * @description Wrapper for PJN_Assistance_Program__c queries. Allows for mocking of responses
 *              since customers can configure the PJN_Active__c field
 * @group       CoverageInvestigation
 */
public with sharing class PJN_AssistanceProgramQuery {

    public List<PJN_Assistance_Program__c> activeByCarePlanId(Set<String> fields, Set<Id> carePlanIds) {
        return Database.query(
            'SELECT ' + String.join(new List<String>(fields), ', ') + ' ' +
            'FROM PJN_Assistance_Program__c ' +
            'WHERE PJN_Active__c = true ' +
            'AND PJN_Care_Plan__c IN :carePlanIds'
        );
    }
}