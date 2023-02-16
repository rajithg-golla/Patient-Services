/**
 * @author      Mavens
 * @group       CaseFieldConfigurations
 * @description Accessor class for PJN_Case_Field_Configuration__mdt custom metadata
 */
public with sharing class PJN_CaseFieldConfigurations {

    public static List<PJN_Case_Field_Configuration__mdt> all {
        get {
            if (all == null) {
                all = Database.query(baseQuery);
                if (Test.isRunningTest()) {
                    all = new PJN_TestFactoryCaseFieldConfiguration().createCaseFieldsConfigurationDefaulted();
                }
            }
            return all;
        }
        set;
    }

    public static List<PJN_Case_Field_Configuration__mdt> withCaseTeamRole {
        get {
            if (withCaseTeamRole == null) {
                String query = baseQuery + ' WHERE PJN_Case_Team_Role_Mapping__c != null';
                withCaseTeamRole = Database.query(query);
                if (Test.isRunningTest()) {
                    withCaseTeamRole = new PJN_TestFactoryCaseFieldConfiguration().createCaseFieldsConfigurationDefaulted();
                }
            }
            return withCaseTeamRole;
        }
        set;
    }

    public static String baseQuery {
        get {
            Set<String> fields = new Set<String>{
                'PJN_Case_Field_API_Name__c',
                'PJN_Case_Team_Role_Mapping__c',
                'PJN_Case_Team_Inverse_Role_Mapping__c',
                'PJN_Delete_Care_Team_Role_on_change__c',
                'PJN_Reciprocal_Role__c',
                'PJN_Reciprocal_Inverse_Role__c',
                'PJN_Reciprocal_Role_Case_Field__c',
                'PJN_Reciprocal_Inverse_Role_Case_Field__c',
                'PJN_Account_Record_Type__c',
                'MVN_Account_Role_Case_Field__c',
                'MVN_Account_Role_Mapping__c',
                'MVN_Account_Record_Type__c'
            };

            return 'SELECT ' + String.join(new List<String>(fields), ', ')
                + ' FROM PJN_Case_Field_Configuration__mdt';
        }
    }
}