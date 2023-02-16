/**
 * @author      Mavens
 * @date        July 28, 2021
 * @description Automation of creation of PAP renewal activity 60 days prior to PAP expiration.
 */
public with sharing class MVN_PapRenewalActivityBatch implements Schedulable, Database.Batchable<sObject> {

    /**
     * Schedule execute method which will start batch job
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) { // NOPMD - SC is standard parameter name.
        Id batchJobId = Database.executeBatch(new MVN_PapRenewalActivityBatch(), 200);
    }

    /**
     * Collect the records or objects to pass to the interface method execute.
     * @param bc
     * @returns `Database.QueryLocator`
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date searchDate = Date.today().addDays(65);
        List<Id> recordTypeIds = new List<Id>{
            Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Patient_Assistance_Program').getRecordTypeId(),
            Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Patient_Assistance_Program_Locked').getRecordTypeId()
        };

        return Database.getQueryLocator([SELECT PJN_Account__c, PJN_Care_Plan__c, PJN_Care_Plan__r.OwnerId, MVN_Expiration_Date_Formula__c FROM PJN_Assistance_Program__c WHERE MVN_Expiration_Date_Formula__c = :searchDate AND RecordTypeId IN :recordTypeIds AND PJN_Outcome__c = 'Eligible']);
    }

    /**
     * Processing for each chunk of data.
     * @param bc
     * @param scope
     */
    public void execute(Database.BatchableContext bc, List<PJN_Assistance_Program__c> scope) {
        List<Case> activities = new List<Case>();

        for (PJN_Assistance_Program__c program : scope) {
            Date dueDate = program.MVN_Expiration_Date_Formula__c;
            dueDate = dueDate.addDays(-60);

            activities.add(
                new Case(
                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                    AccountId = program.PJN_Account__c,
                    ParentId = program.PJN_Care_Plan__c,
                    HealthCloudGA__DueDate__c = dueDate,
                    Subject = System.Label.MVN_PAP_Renewal_Activity_Subject,
                    Description = System.Label.MVN_PAP_Renewal_Activity_Description,
                    OwnerId = program.PJN_Care_Plan__r.OwnerId
                )
            );
        }

        insert activities;
    }

    /**
     * Finish method.
     * @param bc
     */
    public void finish(Database.BatchableContext bc) { //NOPMD
    }
}