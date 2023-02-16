/**
 * @author      Mavens
 * @description Interface describing an implementation of CRM Enrollment integration connector.
 */
public interface PJN_ICRMEnrollmentConnector {
    Map<String, String> mapEvents(PJN_EventToCRMHdlr.ConnectionWrapper wrapper);
    List<SObject> sendToCRM(Map<String, String> jsonEnrollmentStatusMap);
}