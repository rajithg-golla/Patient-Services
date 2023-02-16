/**
 * @author      Mavens
 * @description Used by quick action on the Case record to Close Case
 * @group       CaseActions
 */
public with sharing class MVN_RestatementRTUpdateCtrl {
    /**
    * close case
    * @param    Id      recordId
    */
    @AuraEnabled public static void switchRT(Id recordId) {
        Id restatementStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                                .get('MVN_Therapy_Status_Restatement').getRecordTypeId();
        try {
            update new PJN_Event__c(
                Id = recordId,
                RecordTypeId = restatementStatusUpdateRT
            );
        } catch(AuraHandledException ex) {
            throw PJN_AuraHandledExceptionUtil.handleAuraException(ex);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}