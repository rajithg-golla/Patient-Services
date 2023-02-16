/**
 * @author      Mavens
 * @group       AdobeSign
 * @description On insertion of an Agreement_Update_MVN__e, it will update the corresponding Adobe Sign Agreement as a workaround for Site Guest privilege restrictions.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AdobeSignAgreementUpdateHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {
        List<echosign_dev1__SIGN_Agreement__c> agreements = new List<echosign_dev1__SIGN_Agreement__c>();

        for (Agreement_Update_MVN__e agreementUpdate : (List<Agreement_Update_MVN__e>) trigger.new) {
            if (agreementUpdate.Status_MVN__c != NULL) {
                agreements.add(new echosign_dev1__SIGN_Agreement__c(
                    Id = agreementUpdate.Agreement_MVN__c,
                    echosign_dev1__Status__c = agreementUpdate.Status_MVN__c
                ));
            }
        }

        System.debug('#### updating agreements: ' + agreements);
        update agreements;
    }
}