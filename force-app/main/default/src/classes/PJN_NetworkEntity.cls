/**
 * Veeva Network entity
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkEntity {

    /**
     * Network Entity Id
     */
    public String entityId;

    /**
     * Network Entity type
     */
    public String entityType;

    /**
     * Network Change Request Id
     */
    public String changeRequestId;

    /**
     * Network Result
     */
    public String result;

    /**
     * Network Status
     */
    public String status;

    /**
     * Network record attributes
     */
    public PJN_NetworkRecord entity;

    /**
     * Veeva Network Entity or child constructor using Network response provided
     * @param entityResponse    Network entity response
     */
    public PJN_NetworkEntity(Map<String, Object> entityResponse) {
        this.entityId = entityResponse.containsKey('entityId') ?
            String.valueOf(entityResponse.get('entityId')) :
            String.valueOf(entityResponse.get('vid__v'));

        if (String.isBlank(this.entityId)) {
            this.entityId = String.IsNotBlank(String.valueOf(entityResponse.get('reserved_vid'))) ?
                String.valueOf(entityResponse.get('reserved_vid')) :
                String.valueOf(entityResponse.get('vid_key'));
        }

        this.entityType = entityResponse.containsKey('entityType') ?
            String.valueOf(entityResponse.get('entityType')) :
            String.valueOf(entityResponse.get('entity_type'));

        this.changeRequestId = String.valueOf(entityResponse.get('change_request_id'));
        this.result = String.valueOf(entityResponse.get('result__v'));
        this.status = String.valueOf(entityResponse.get('status__v'));

        this.entity = new PJN_NetworkRecord((Map<String, Object>) entityResponse.get('entity'));
    }
}