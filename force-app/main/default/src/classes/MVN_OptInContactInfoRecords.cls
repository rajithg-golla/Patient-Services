/**
 * @author      Mavens
 * @group       ContactInformation
 * @description Create Channel Consent as Opted-In for Contact Information Records on Care Plan creation
 */
public with sharing class MVN_OptInContactInfoRecords implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {

        Map<Id, Case> carePlanByAccountId = getCarePlans();
        if (carePlanByAccountId.isEmpty()) {
            return;
        }
        List<PJN_Channel_Consent__c> consents = PJN_ConsentHdlr.buildConsentForContactInformationBatch(
                        carePlanByAccountId, PJN_ConsentHdlr.OPT_IN
        );
        upsert consents;
    }

    /**
     * Get only those cases with RT CarePlan and store them in a Map by Account Id
     * @return   Map<Id, Case>
     */
    private Map<Id, Case> getCarePlans() {
        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();

        Map<Id, Case> carePlanByAccountId = new Map<Id, Case>();
        for (Case newCase : (List<Case>) Trigger.New) {
            if (newCase.RecordTypeId == carePlanRecordTypeId) {
                carePlanByAccountId.put(newCase.AccountId, newCase);
            }
        }
        return carePlanByAccountId;
    }
}