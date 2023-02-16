/**
 * @author Mavens
 * @date Nov 2020
 * @description This trigger facilitates enrollment processed in PJN to create "Suggestion" record in Veeva CRM.
 * @group case-triggers
 */
public without sharing class PJN_CaseToCRMHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    @testVisible private static PJN_CRMConnectionSettingQuery crmConnectionSettingQuery = new PJN_CRMConnectionSettingQuery();

    /**
     * Handle the trigger call
     */
    public void handle() {
        for (PJN_CRM_Connection_Setting__mdt connectionSetting : crmConnectionSettingQuery.queryBySettingByType('Case Escalation')) {
            ConnectionWrapper wrapper  = new ConnectionWrapper(connectionSetting);
            for (SObject newCase : Trigger.new) {
                if ((Test.isRunningTest() && connectionSetting.PJN_Trigger_Field__c != NULL && (Boolean) newCase.get(connectionSetting.PJN_Trigger_Field__c)) || (connectionSetting.PJN_Trigger_Field__c != NULL && (Boolean) newCase.get(connectionSetting.PJN_Trigger_Field__c))) {
                    wrapper.addCase((Case) newCase);
                }
            }
            System.debug('wrapper :: ' + wrapper);
            if(!wrapper.caseMap.isEmpty()) {
                System.enqueueJob(new PJN_CaseToCRMQueueable(JSON.serialize(wrapper)));
            }
        }
    }

    public class ConnectionWrapper {
        public PJN_CRM_Connection_Setting__mdt connectionSetting;
        public Map<Id, Case> caseMap;

        public ConnectionWrapper(PJN_CRM_Connection_Setting__mdt connectionSetting) {
            this.connectionSetting = connectionSetting;
            this.caseMap = new Map<Id, Case>();
        }

        public void addCase(Case newCase) {
            caseMap.put(newCase.Id, newCase);
        }
    }
}