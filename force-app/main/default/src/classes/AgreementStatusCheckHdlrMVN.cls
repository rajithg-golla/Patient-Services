/**
 * @author      Mavens
 * @description Calls out Adobe Sign to check the status of an agreement on insert. This is to catch if an agreement is signed in the window between receiving an agreement id and passing it to the WebHook.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AgreementStatusCheckHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {

        Boolean canCallFuture = !System.isFuture() && !System.isBatch() && !System.isQueueable() && !System.isScheduled();

        if (canCallFuture) {
            List<Id> agreementIds = new List<Id>();
            for (echosign_dev1__SIGN_Agreement__c agreement : (List<echosign_dev1__SIGN_Agreement__c>) trigger.new) {
                agreementIds.add(agreement.Id);
            }

            updateAgreementsAndPendingLeads(agreementIds);
        }
    }

    @future (callout=true)
    public static void updateAgreementsAndPendingLeads(List<Id> agreementIds) {
        List<echosign_dev1__SIGN_Agreement__c> agreements = [SELECT echosign_dev1__Document_Key__c, echosign_dev1__Status__c, Pending_Lead_MVN__c FROM echosign_dev1__SIGN_Agreement__c WHERE Id IN :agreementIds AND echosign_dev1__Document_Key__c != NULL];

        for (echosign_dev1__SIGN_Agreement__c agreement : agreements) {
            if (agreement.Pending_Lead_MVN__c != NULL && agreement.echosign_dev1__Status__c != 'Signed' && !Test.isRunningTest()) {
                Map<String, Object> agreementMap = AdobeSignAPIMVN.getAgreement(agreement.echosign_dev1__Document_Key__c);
                String status = (String) agreementMap.get('status');
                agreement.echosign_dev1__Status__c = status.replace('_', ' ');
            }
        }

        update agreements;
    }
}