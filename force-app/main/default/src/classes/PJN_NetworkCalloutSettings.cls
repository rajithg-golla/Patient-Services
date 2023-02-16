/**
 * Settings to make a callout to Veeva Network
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkCalloutSettings {
    /**
     * Veeva Network method endpoint
     */
    private String endpoint;

    /**
     * HTTP Method for current endpoint
     */
    private String httpMethod;

    /**
     * Content type for method body
     */
    private String contentType;

    /**
     * Veeva Network callout settings constructor
     * @param endpoint      Method endpoint
     * @param httpMethod    HTTP method
     * @param contentType   Body content type
     */
    public PJN_NetworkCalloutSettings(String endpoint, String httpMethod, String contentType) {
        this.endpoint = endpoint;
        this.httpMethod = httpMethod;
        this.contentType = contentType;
    }

    /**
     * Get HTTP request with network settings and body
     * @param body  HTTP Request body to send into Veeva Network
     * @returns `HttpRequest`
     */
    public HttpRequest getRequest(String body) {
        HttpRequest req = new HttpRequest();
        if(String.isNotBlank(body)) {
            req.setBody(body);
        }
        PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;
        String networkNamedCredential = pjnSetting != null ? pjnSetting.PJN_Network_Named_Credential__c : PJN_NetworkConstants.NETWORK_NAMED_CREDENTIAL;
        String networkAPIVersion = pjnSetting != null ? pjnSetting.PJN_Network_API_Version__c : PJN_NetworkConstants.NETWORK_API_VERSION;
        String thisEndpoint = 'callout:' + networkNamedCredential + '/api/' + networkAPIVersion + endpoint;
        req.setEndpoint(thisEndpoint);
        req.setMethod(httpMethod);
        req.setTimeout(5000);
        req.setHeader('Accept', 'application/json');

        if(String.IsNotBlank(contentType)) {
            req.setHeader('Content-Type', contentType);
        }

        return req;
    }
}