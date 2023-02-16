/**
 * @author      Mavens
 * @description If an Agreement is inserted or the status is updated on an update AND it’s associated to a Pending Lead it updates the Agreement Status on the Pending Lead. If the Pending Lead’s agreement status is changed to Signed it will kick off the Lead conversion process.
 */ 
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AgreementUpdatePendingLeadHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {
        List<Pending_Lead_MVN__c> pendingLeads = new List<Pending_Lead_MVN__c>();
        for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>) trigger.new) {
            System.debug('#### agreement: ' + agreement);
            System.debug('#### agreement.Pending_Lead_MVN__c: ' + agreement.Pending_Lead_MVN__c);
            if (Trigger.isInsert && agreement.Pending_Lead_MVN__c != NULL) {
                pendingLeads.add(buildPendingLead(agreement));
            } else if (Trigger.isUpdate && agreement.Pending_Lead_MVN__c != NULL) {
                echosign_dev1__SIGN_Agreement__c oldAgreement = (echosign_dev1__SIGN_Agreement__c) trigger.oldMap.get(agreement.Id);
                System.debug('#### oldAgreement.echosign_dev1__Status__c: ' + oldAgreement.echosign_dev1__Status__c);
                System.debug('#### agreement.echosign_dev1__Status__c: ' + agreement.echosign_dev1__Status__c);
                if (oldAgreement.echosign_dev1__Status__c != agreement.echosign_dev1__Status__c) {
                    pendingLeads.add(buildPendingLead(agreement));
                }
            }
        }

        System.debug('#### updating pendingLeads: ' + pendingLeads);
        update pendingLeads;
    }

    private static Pending_Lead_MVN__c buildPendingLead(echosign_dev1__SIGN_Agreement__c agreement) {
        return new Pending_Lead_MVN__c(
            Id = agreement.Pending_Lead_MVN__c,
            Agreement_Status_MVN__c = agreement.echosign_dev1__Status__c
        );
    }
}