/**
 * @author      Mavens
 * @date        July 28, 2021
 * @description Automation of creation of PA re-authorization 30 days prior to PA expiration date.
 */
public with sharing class MVN_PaReauthActivityBatch implements Schedulable, Database.Batchable<sObject> {

    /**
     * Schedule execute method which will start batch job
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) { // NOPMD - SC is standard parameter name.
        Id batchJobId = Database.executeBatch(new MVN_PaReauthActivityBatch(), 200);
    }

    /**
     * Collect the records or objects to pass to the interface method execute.
     * @param bc
     * @returns `Database.QueryLocator`
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date searchDate = Date.today().addDays(35);

        return Database.getQueryLocator([SELECT PJN_Care_Plan__c, PJN_Care_Plan__r.AccountId, PJN_Care_Plan__r.MVN_Coordinator__c, PJN_Care_Plan__r.OwnerId, PJN_Expiration_Date__c FROM PJN_Prior_Authorization__c WHERE PJN_Expiration_Date__c = :searchDate AND PJN_Outcome__c = 'Approved']);
    }

    /**
     * Processing for each chunk of data.
     * @param bc
     * @param scope
     */
    public void execute(Database.BatchableContext bc, List<PJN_Prior_Authorization__c> scope) {
        List<Case> activities = new List<Case>();

        for (PJN_Prior_Authorization__c priorAuth : scope) {
            Date dueDate = priorAuth.PJN_Expiration_Date__c;
            dueDate = dueDate.addDays(-30);

            Boolean coordinatorEmpty = priorAuth.PJN_Care_Plan__r.MVN_Coordinator__c != NULL;

            activities.add(
                new Case(
                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                    AccountId = priorAuth.PJN_Care_Plan__r.AccountId,
                    ParentId = priorAuth.PJN_Care_Plan__c,
                    HealthCloudGA__DueDate__c = dueDate,
                    Subject = System.Label.MVN_PA_Reauthorization_Activity_Subject,
                    Description = System.Label.MVN_PA_Reauthorization_Activity_Description,
                    OwnerId = coordinatorEmpty ? priorAuth.PJN_Care_Plan__r.MVN_Coordinator__c : priorAuth.PJN_Care_Plan__r.OwnerId
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