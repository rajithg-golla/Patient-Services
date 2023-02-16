/**
 * Veeva Network Callout authorization settings
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkAuth {
    /**
     * global setting
     */
    public static PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;

    private static final String NETWORK_NAMED_CREDENTIAL = pjnSetting != null && String.isNotBlank(pjnSetting.PJN_Network_Named_Credential__c) ?
        pjnSetting.PJN_Network_Named_Credential__c :
        PJN_NetworkConstants.NETWORK_NAMED_CREDENTIAL;

    /**
     * Cache keys do not allow all characters allowed by named credentials API names so we hash it for the key
     */
    private static final String CACHE_KEY = 'local.PJNIntegrationTokens.Network' + Math.abs(PJN_NetworkConstants.NETWORK_NAMED_CREDENTIAL.hashCode());

    /**
     * Current Session Authorization Token
     */
    private String sessionAuthToken;

    /**
     * Initialize session authorization token cached or empty if no exists or force a new one
     * @param forceNewToken Defines if needs a new one in any case
     */
    public PJN_NetworkAuth(Boolean forceNewToken) {
        sessionAuthToken = !forceNewToken && Cache.Org.contains(CACHE_KEY) ?
            String.valueOf(Cache.Org.get(CACHE_KEY)) :
            '';
    }

    /**
     * Returns the session authorization token
     * @returns `String`
     */
    public String getAuthToken() {
        return sessionAuthToken;
    }

    /**
     * Stores in cache session authorization token tto use on a future call
     * @param sessionAuthToken  Session authorization token to save
     */
    public void saveAuthToken(String sessionAuthToken) {
        this.sessionAuthToken = sessionAuthToken;
        Cache.org.put(CACHE_KEY, sessionAuthToken, 900);
    }

    /**
     * Gets HTTP Request to obtain a new Authorization token from Veeva Network
     * @returns `HttpRequest`
     */
    public HttpRequest getAuthTokenRequest() {
        PJN_NetworkCalloutSettings networkCalloutSetting = new PJN_NetworkCalloutSettings('/auth', 'POST', null);

        return networkCalloutSetting.getRequest('username={!$Credential.Username}&password={!$Credential.Password}');
    }
}