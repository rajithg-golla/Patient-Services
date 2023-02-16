/**
 * Queuable to send Cases to CRM
 * @author  Mavens
 * @group   CRM
 */
public class PJN_CaseToCRMQueueable implements Queueable, Database.AllowsCallouts {
    /**
     *  List of cases to send to CRM
     */
    private PJN_CaseToCRMHdlr.ConnectionWrapper wrapper;

    /**
     * Initialize cases to send to CRM
     * @param wrapper
     */
    public PJN_CaseToCRMQueueable(String wrapper) {
        this.wrapper = (PJN_CaseToCRMHdlr.ConnectionWrapper) JSON.deserialize(wrapper, PJN_CaseToCRMHdlr.ConnectionWrapper.class);
    }

    /**
     * Queue execute method which converts DCR to Network DCR and send them to Veeva Network
     * @param context
     */
    public void execute(QueueableContext context) {
        System.debug('this.wrapper in the queuable! ' + this.wrapper);
        if(!this.wrapper.caseMap.isEmpty()) {
            Type crmSuggestionConnector = Type.forName(this.wrapper.connectionSetting.PJN_CRM_Connection_Class__c);
            PJN_ICaseToCRMConnector enrollmentConnectorInstance = (PJN_ICaseToCRMConnector) crmSuggestionConnector.newInstance();
            String jsonSuggestionStatus = enrollmentConnectorInstance.mapCases(this.wrapper);
            if (jsonSuggestionStatus != NULL) {
                List<Case> cases = enrollmentConnectorInstance.sendToCRM(jsonSuggestionStatus);
                update cases;
            }
        }
    }
}