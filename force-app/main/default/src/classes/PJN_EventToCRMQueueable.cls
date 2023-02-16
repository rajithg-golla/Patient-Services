/**
 * Queuable to send events to CRM
 * @author  Mavens
 * @group   CRM
 */
public class PJN_EventToCRMQueueable implements Queueable, Database.AllowsCallouts {
    /**
     *  List of events to send to CRM
     */
    private PJN_EventToCRMHdlr.ConnectionWrapper wrapper;

    /**
     * Initialize events to send to CRM
     * @param wrapper
     */
    public PJN_EventToCRMQueueable(String wrapper) {
        this.wrapper = (PJN_EventToCRMHdlr.ConnectionWrapper) JSON.deserialize(wrapper, PJN_EventToCRMHdlr.ConnectionWrapper.class);
    }

    /**
     * Queue execute method which converts DCR to Network DCR and send them to Veeva Network
     * @param context
     */
    public void execute(QueueableContext context) {
        System.debug('this.wrapper in the queuable! ' + this.wrapper);
        if (!this.wrapper.eventMap.isEmpty()) {
            Type crmEnrollmentConnector = Type.forName(this.wrapper.connectionSetting.PJN_CRM_Connection_Class__c);
            PJN_ICRMEnrollmentConnector enrollmentConnectorInstance = (PJN_ICRMEnrollmentConnector) crmEnrollmentConnector.newInstance();
            Map<String, String> jsonEnrollmentStatusMap = enrollmentConnectorInstance.mapEvents(this.wrapper);
            List<PJN_Event__c> returnedSObjects = enrollmentConnectorInstance.sendToCRM(jsonEnrollmentStatusMap);
            update returnedSObjects; // NOPMD - disregard CRUD permission and despite being in loop, this shouldn't be called more than once... or twice?
        }
    }
}