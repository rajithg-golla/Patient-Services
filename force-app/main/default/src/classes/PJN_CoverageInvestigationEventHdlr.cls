/**
 * @author      Mavens
 * @date       05/2021
 * @description Coverage Investigation Event handler to process logic based on event values
 * @group       CoverageInvestigation
 */
public with sharing class PJN_CoverageInvestigationEventHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        Set<Id> coverageInvestigationIds = new Set<Id>();
        List<PJN_Event__c> scope;
        if (Trigger.isDelete) {
            scope = (List<PJN_Event__c>) Trigger.old;
        } else {
            scope = (List<PJN_Event__c>) Trigger.new;
        }

        for (PJN_Event__c event : scope) {
            if (event.PJN_Coverage_Investigation__c != null && String.isNotBlank(event.PJN_Access_Type__c)) {
                // if there are more than one event for the coverage investigation the last in
                // will be the winner. This is the desired outcome.
                coverageInvestigationIds.add(event.PJN_Coverage_Investigation__c);
            }
        }

        if (coverageInvestigationIds.isEmpty()) {
            return; // nothing to process
        }

        List<PJN_Coverage_Investigation__c> investigations = [
            SELECT
                Id,
                PJN_Access_Type__c,
                (
                    SELECT PJN_Access_Type__c
                    FROM Events__r
                    WHERE PJN_Access_Type__c != null
                    ORDER BY PJN_Start_Date__c DESC NULLS LAST
                )
            FROM PJN_Coverage_Investigation__c
            WHERE Id IN :coverageInvestigationIds
        ];

        for (PJN_Coverage_Investigation__c investigation : investigations) {
            if (!investigation.Events__r.isEmpty()) {
                PJN_Event__c event = investigation.Events__r[0];
                investigation.PJN_Access_Type__c = event.PJN_Access_Type__c;
            } else {
                investigation.PJN_Access_Type__c = null;
            }
        }

        update investigations;
    }
}