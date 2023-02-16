/**
 * @author      Mavens
 * @description Interface describing an implementation of CRM Suggestion integration connector.
 */
public interface PJN_ICaseToCRMConnector {
    String mapCases(PJN_CaseToCRMHdlr.ConnectionWrapper wrapper);
    List<Case> sendToCRM(String jsonEnrollmentStatus);
}