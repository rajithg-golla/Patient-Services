/**
 * Veeva Network Response
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkResponse {

    /**
     * Response Status.
     */
    public String responseStatus;

    /**
     * Errors during network callout
     */
    public List<PJN_NetworkError> errors;

    /**
     * Response Error message if no errors.
     */
    public String responseMessage;

    /**
     * Network session id
     */
    public String sessionId;

    /**
     * Change request id
     */
    public String changeRequestId;

    /**
     * Veeva Network Reserved Id
     */
    public String reservedVid;

    /**
     * List of entities
     */
    public List<PJN_NetworkEntity> entities;

    /**
     * List of entities
     */
    public List<PJN_NetworkEntity> changeRequests;

    /**
     * Constructor of Network Response
     * @param networkResponse   Network response
     */
    public PJN_NetworkResponse(Map<String, Object> networkResponse) {
        this.responseStatus = String.valueOf(networkResponse.get('responseStatus'));
        this.responseMessage = String.valueOf(networkResponse.get('responseMessage'));
        this.sessionId = String.valueOf(networkResponse.get('sessionId'));
        this.changeRequestId = String.valueOf(networkResponse.get('change_request_id'));
        this.reservedVid = String.valueOf(networkResponse.get('reserved_vid'));

        List<Object> errorsObj = (List<Object>) networkResponse.get('errors');

        if (errorsObj != null) {
            this.errors = new List<PJN_NetworkError>();
            for (Object errorObj : errorsObj) {
                this.errors.add(new PJN_NetworkError((Map<String, Object>) errorObj));
            }
        }

        List<Object> entitiesObj = (List<Object>) networkResponse.get('entities');

        if (entitiesObj != null) {
            this.entities = new List<PJN_NetworkEntity>();
            for (Object entityObj : entitiesObj) {
                this.entities.add(new PJN_NetworkEntity((Map<String, Object>) entityObj));
            }
        }

        List<Object> changeRequestsObj = (List<Object>) networkResponse.get('change_requests');

        if (changeRequestsObj != null) {
            this.changeRequests = new List<PJN_NetworkEntity>();
            for (Object changeRequestObj : changeRequestsObj) {
                this.changeRequests.add(new PJN_NetworkEntity((Map<String, Object>) changeRequestObj));
            }
        }
    }
}