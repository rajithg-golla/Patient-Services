/**
 * @author      Mavens
 * @date        11/2020
 * @description Handler for setting the parent care plan with the active coverage investigation
 * @group       CoverageInvestigation
 */
public with sharing class PJN_ActiveCoverageInvestigationHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    private static Set<Id> activeInvestigationCarePlans = new Set<Id>();

    public void handle() {
        if ( trigger.isBefore ) {
            for (PJN_Coverage_Investigation__c investigation : (List<PJN_Coverage_Investigation__c>) Trigger.new) {
                if (investigation.PJN_Set_as_Active__c) {
                    investigation.PJN_Set_as_Active__c = false;
                    activeInvestigationCarePlans.add(investigation.PJN_Care_Plan__c);
                }
            }
        } else if (!activeInvestigationCarePlans.isEmpty()) {
            Map<Id, Case> carePlans  = new Map<Id, Case>();

            for (PJN_Coverage_Investigation__c investigation : (List<PJN_Coverage_Investigation__c>) Trigger.new) {
                if (activeInvestigationCarePlans.contains(investigation.PJN_Care_Plan__c)) {
                    carePlans.put(
                        investigation.PJN_Care_Plan__c,
                        new Case(
                            Id = investigation.PJN_Care_Plan__c,
                            PJN_Active_Coverage_Investigation__c = investigation.Id
                        )
                    );
                }
            }
            update carePlans.values();
        }
    }
}