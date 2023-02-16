/**
 * @author      Mavens
 * @group       RBM
 * @description Batch job to set the Share with RBM flag on Care Plans
 */
public with sharing class MVN_ShareWithRBMBatchSch implements Schedulable, Database.Batchable<sObject> {
    
    public void execute(SchedulableContext SC) {
        Id jobId = Database.executeBatch(new MVN_ShareWithRBMBatchSch());
    }

    public static void schedule(String cronExpression) {
        unschedule();
        MVN_ShareWithRBMBatchSch shareWithRBMSchedulable = new MVN_ShareWithRBMBatchSch();
        Id jobId = System.schedule('ShareWithRBMBatch', cronExpression, shareWithRBMSchedulable);
    }

    public static void unschedule() {
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :('ShareWithRBMBatch'+'%')] ) {
            System.abortJob(ct.Id);
        }
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT Id,
                       RecordTypeId,
                       PJN_Program_DeveloperName__c,
                       PJN_Therapy_Status__c,
                       PJN_Therapy_Sub_Status__c,
                       MVN_Pharmacy_Status__c,
                       MVN_Last_Pharmacy_Status_Update__c,
                       MVN_Days_in_Pharmacy_Status__c,
                       MVN_Last_Therapy_Status_Update__c,
                       MVN_Days_in_Therapy_Status__c,
                       MVN_Share_with_RBM__c
                  FROM Case
                 WHERE RecordType.DeveloperName = 'CarePlan'
            ]
        );
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> carePlans = scope;
        MVN_ShareWithRBM.share(carePlans);
        update carePlans;
    }
    
    public void finish(Database.BatchableContext BC) {
    }
}