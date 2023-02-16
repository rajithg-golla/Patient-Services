@SuppressWarnings('PMD') // excessive public variables and names are for the purposes of creating JSON
public with sharing class PJN_VeevaCRMSuggestion {

    public Attributes attributes {get; set;}
    public String Account_vod_c {get; set;}
    public String PJN_External_Id_c {get; set;}
    public String PJN_Incoming_Record_Type_c {get; set;}
    public String Priority_vod_c {get; set;}
    public String Reason_vod_c {get; set;}
    public String Title_vod_c {get; set;}
    public Boolean Display_Dismiss_vod_c {get; set;}
    public Boolean Display_Mark_As_Complete_vod_c {get; set;}
    public Boolean Display_Score_vod_c {get; set;}

    public PJN_VeevaCRMSuggestion(Case c, Map<Id, Id> accountIdToVeevaAccountId) {
        this.Account_vod_c = accountIdToVeevaAccountId.get(c.PJN_Physician_Id__c);
        this.PJN_External_Id_c = c.Id;
        this.PJN_Incoming_Record_Type_c = c.PJN_Veeva_CRM_Suggestion_Record_Type__c;
        this.Reason_vod_c = c.Description;
        this.Title_vod_c = c.Subject;
        this.Priority_vod_c = 'Urgent_vod';
        this.attributes = new Attributes(c.Id);
        this.Display_Dismiss_vod_c = true;
        this.Display_Mark_As_Complete_vod_c = true;
        this.Display_Score_vod_c = true;
    }

    public class Attributes {
        public String type {get; set;}
        public String referenceId {get; set;}

        public Attributes(Id caseId) {
            type = 'Suggestion_vod__c';
            referenceId = caseId;
        }
    }
}