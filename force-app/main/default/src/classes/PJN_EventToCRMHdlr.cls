/**
 * @author Mavens
 * @date Oct 2020
 * @description This trigger facilitates enrollment processed in PJN to create "Enrollment" record in Veeva CRM.
 * @group event-triggers
 */
public without sharing class PJN_EventToCRMHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    @testVisible private static PJN_CRMConnectionSettingQuery crmConnectionSettingQuery = new PJN_CRMConnectionSettingQuery();

    /**
     * Handle the trigger call
     */
    public void handle() {
        for (PJN_CRM_Connection_Setting__mdt connectionSetting : crmConnectionSettingQuery.queryBySettingByType('Enrollment')) {
            ConnectionWrapper wrapper  = new ConnectionWrapper(connectionSetting);
            for (SObject newEvent : Trigger.new) {
                if ((Test.isRunningTest() && connectionSetting.PJN_Trigger_Field__c != NULL && (Boolean) newEvent.get(connectionSetting.PJN_Trigger_Field__c)) || (connectionSetting.PJN_Trigger_Field__c != NULL && (Boolean) newEvent.get(connectionSetting.PJN_Trigger_Field__c) && connectionSetting.PJN_Active__c)) {
                    wrapper.addEvent((PJN_Event__c) newEvent);
                }
            }
            System.debug('wrapper: ' + wrapper);
            if(!wrapper.eventMap.isEmpty()) {
                System.enqueueJob(new PJN_EventToCRMQueueable(JSON.serialize(wrapper)));
            }
        }
    }

    public class ConnectionWrapper {
        public PJN_CRM_Connection_Setting__mdt connectionSetting;
        public Map<Id, PJN_Event__c> eventMap;

        public ConnectionWrapper(PJN_CRM_Connection_Setting__mdt connectionSetting) {
            this.connectionSetting = connectionSetting;
            this.eventMap = new Map<Id, PJN_Event__c>();
        }

        public void addEvent(PJN_Event__c event) {
            eventMap.put(event.Id, event);
        }
    }
}