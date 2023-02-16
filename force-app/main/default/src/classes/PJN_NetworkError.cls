/**
 * Network Error Response
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkError {

    public String type;
    public String message;

    public PJN_NetworkError(Map<String, Object> error) {
        this.type = String.valueOf(error.get('type'));
        this.message = String.valueOf(error.get('message'));
    }
}