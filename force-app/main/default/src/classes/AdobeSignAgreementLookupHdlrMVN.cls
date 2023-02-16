/**
 * @author      Mavens
 * @group       AdobeSign
 * @description On update of Case, it will update the corresponding Adobe Sign Agreement with lookups.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class AdobeSignAgreementLookupHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {
        processCases((List<Case>) Trigger.new);
    }

    public static void processCases(List<Case> cases) {
        Map<Id, AgreementWrapper> wrapperLeadMap = new Map<Id, AgreementWrapper>();
        for (Case carePlan : cases) {
            if (isAgreementStampingNeeded(carePlan)) {
                wrapperLeadMap.put(carePlan.Converted_Lead_MVN__c, new AgreementWrapper(carePlan.Id, carePlan.AccountId, carePlan.Converted_Lead_MVN__c));
            }
        }

        if (wrapperLeadMap.size() > 0) {
            Map<Id, AgreementWrapper> wrapperPendingLeadMap = new Map<Id, AgreementWrapper>();
            for (Lead consumer : queryLeads(wrapperLeadMap.keySet())) {
                AgreementWrapper wrapper = wrapperLeadMap.get(consumer.Id);
                wrapper.pendingLeadId = consumer.Pending_Lead_MVN__c;
                wrapperPendingLeadMap.put(consumer.Pending_Lead_MVN__c, wrapper);
            }

            List<echosign_dev1__SIGN_Agreement__c> agreementsToUpdate = new List<echosign_dev1__SIGN_Agreement__c>();
            for (echosign_dev1__SIGN_Agreement__c agreement : queryAgreements(wrapperPendingLeadMap.keySet())) {
                AgreementWrapper wrapper = wrapperPendingLeadMap.get(agreement.Pending_Lead_MVN__c);
                agreement.Care_Plan_MVN__c = wrapper.carePlanId;
                agreement.CustomConsumer__c = wrapper.leadId;
                agreement.echosign_dev1__Account__c = wrapper.accountId;
                agreementsToUpdate.add(agreement);
            }

            update agreementsToUpdate;
        }
    }

    private static List<Lead> queryLeads(Set<Id> leadIds) {
        return [SELECT Pending_Lead_MVN__c FROM Lead WHERE Id IN :leadIds AND Pending_Lead_MVN__c != NULL];
    }

    private static List<echosign_dev1__SIGN_Agreement__c> queryAgreements(Set<Id> pendingLeadIds) {
        return [SELECT Care_Plan_MVN__c, CustomConsumer__c, echosign_dev1__Account__c, Pending_Lead_MVN__c FROM echosign_dev1__SIGN_Agreement__c WHERE Pending_Lead_MVN__c IN :pendingLeadIds];
    }

    private static Boolean isAgreementStampingNeeded(Case carePlan) {
        if (Trigger.isInsert && carePlan.Converted_Lead_MVN__c != NULL) {
            return true;
        } else if (Trigger.isUpdate && carePlan.Converted_Lead_MVN__c != NULL) {
            Case oldCarePlan = (Case) Trigger.oldMap.get(carePlan.Id);
            if (oldCarePlan.Converted_Lead_MVN__c != carePlan.Converted_Lead_MVN__c) {
                return true;
            }
        }

        return false;
    }

    public class AgreementWrapper {
        public Id carePlanId {get; set;}
        public Id accountId {get; set;}
        public Id leadId {get; set;}
        public Id pendingLeadId {get; set;}

        public AgreementWrapper(Id carePlanId, Id accountId, Id leadId) {
            this.carePlanId = carePlanId;
            this.accountId = accountId;
            this.leadId = leadId;
        }
    }
}