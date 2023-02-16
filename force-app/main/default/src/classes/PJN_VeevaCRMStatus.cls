/**
 * @author Mavens
 * @date Oct 2020
 * @description Wrapper for Enrollment Status object in target org
 * @group event-triggers
 */
@SuppressWarnings('PMD.VariableNamingConventions,PMD.ExcessivePublicCount') // names and public variables are for the purposes of creating json
public with sharing class PJN_VeevaCRMStatus {
    public Attributes attributes {get;set;}
    public String PJN_External_ID_c {get; set;}
    public String PJN_New_Therapy_Status_c {get;set;}
    public String PJN_New_Therapy_Sub_Status_c {get;set;}
    public String PJN_Care_Plan_Number_c {get;set;}
    public String PJN_New_Physician_c {get; set;}
    public String PJN_Previous_Physician_c {get; set;}
    public Enrollment PJN_Enrollment_r {get; set;}

    public PJN_VeevaCRMStatus(PJN_Event__c event, Map<Id, String> accountIdToVeevaNetworkId) {
        this.PJN_External_ID_c = event.Id;
        this.PJN_Care_Plan_Number_c = event.PJN_Care_Plan_Number__c;
        this.PJN_New_Therapy_Status_c = event.PJN_New_Therapy_Status__c;
        this.PJN_New_Therapy_Sub_Status_c = event.PJN_New_Therapy_Sub_Status__c;
        this.PJN_New_Physician_c = event.PJN_New_Physician__c != NULL ? accountIdToVeevaNetworkId.get(event.PJN_New_Physician__c) : NULL;
        this.PJN_Previous_Physician_c = event.PJN_New_Physician__c != NULL ? accountIdToVeevaNetworkId.get(event.PJN_Previous_Physician__c) : NULL;
        this.attributes = new Attributes(event);
        this.PJN_Enrollment_r = new Enrollment(event);
    }

    public class Attributes {
        public String type {get;set;}
        public String referenceId {get;set;}

        public Attributes(PJN_Event__c event) {
            type = 'PJN_Enrollment_Status__c';
            referenceId = event.Id;
        }
    }

    public class Enrollment{
        public String PJN_External_ID_c {get;set;}

        public Enrollment(PJN_Event__c event) {
            PJN_External_ID_c = event.PJN_Case__c;
        }
    }
}