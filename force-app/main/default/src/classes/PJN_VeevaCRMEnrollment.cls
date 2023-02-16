/**
 * @author Mavens
 * @date Oct 2020
 * @description Wrapper for Enrollment object in target org
 * @group event-triggers
 */
@SuppressWarnings('PMD.VariableNamingConventions') // names are for the purposes of creating json
public with sharing class PJN_VeevaCRMEnrollment {
    public Attributes attributes {get;set;}
    public String PJN_External_Id_c {get;set;}
    public String PJN_Care_Plan_Number_c {get; set;}
    public String PJN_Physician_Network_Id_c {get; set;}
    public String PJN_Program_c {get; set;}

    public PJN_VeevaCRMEnrollment(PJN_Event__c event, Map<Id, String> accountIdToVeevaNetworkId, Account acct) {
        this.PJN_External_Id_c = event.PJN_Case__c;
        this.PJN_Care_Plan_Number_c = event.PJN_Care_Plan_Number__c;
        this.PJN_Physician_Network_Id_c = event.PJN_Physician_Network_Id__c != NULL ? accountIdToVeevaNetworkId.get(event.PJN_Physician_Network_Id__c) : NULL;
        this.PJN_Program_c = event.PJN_Program_DeveloperName__c;
        this.attributes = new Attributes(event);
    }

    private String getInitials(Account acct) {
        return getInitial(acct.FirstName) + getInitial(acct.LastName);
    }

    private String getInitial(String nameString) {
        return String.isBlank(nameString) ? '' : nameString.substring(0,1);
    }

    public class Attributes {
        public String type {get;set;}
        public String referenceId {get;set;}

        public Attributes(PJN_Event__c event) {
            type = 'PJN_Enrollment__c';
            referenceId = event.PJN_Case__c;
        }
    }
}