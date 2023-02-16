/**
 * Apex class to call Veeva Network API
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkCallout {

    /**
     * Defined to avoid callout on unnecessary testing
     */
    public static Boolean noRunInTest = Test.isRunningTest();

    /**
     * Callout settings to make a HTTP Request
     */
    private PJN_NetworkCalloutSettings networkCalloutSettings;

    /**
     * Contains the errors of a partial success
     */
    public static List<String> partialSuccessErrors;

    /**
     * Veeva Network Callout exception
     */
    public class NetworkCalloutException extends Exception {}

    /**
     * Veeva Network callout constructor which defines the Network Callout settings
     * @param endpoint      Veeva Network API Method
     * @param httpMethod    GET/POST/PUT
     * @param contentType   HTTP Request content type
     */
    public PJN_NetworkCallout(String endpoint, String httpMethod, String contentType) {
        networkCalloutSettings = new PJN_NetworkCalloutSettings(endpoint, httpMethod, contentType);
    }

    /**
     * Method which calls Veeva Network using a body
     * @param body  HTTP Request body for the callout
     * @returns `Map<String, Object>`
     */
    public PJN_NetworkResponse callVeevaNetwork(String body) {
        PJN_NetworkResponse deserializeResponse;

        try {
            System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Callout body: ' + body);
            HttpRequest req = buildCalloutRequest(false, body);

            deserializeResponse = doCallout(req);
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(PJN_PublishTransactionLog.convertHttpRequest(req), System.JSON.serialize(deserializeResponse));
            PJN_PublishTransactionLog.addDebug(transactionLog);
            checkForNetworkErrors(deserializeResponse);
        } catch (NetworkCalloutException e) {
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(body, e.getMessage() + ' - ' + e.getStackTraceString());
            PJN_PublishTransactionLog.addError(transactionLog);
            System.debug(LoggingLevel.ERROR, PJN_NetworkConstants.NETWORK_DEBUG + '::Exception thrown: ' + e.getMessage());

            String invalidSessionMsg = PJN_NetworkStatusMapping.getMessageForNetwokStatus(PJN_NetworkConstants.NETWORK_INVALID_SESSION);

            if (String.isNotBlank(invalidSessionMsg) && e.getMessage().contains(invalidSessionMsg)) {
                HttpRequest req = buildCalloutRequest(true, body);

                deserializeResponse = doCallout(req);
                checkForNetworkErrors(deserializeResponse);
            } else if (e.getMessage().toLowerCase().contains('script-thrown exception')) {
                throw new AuraHandledException(Label.PJN_Network_Configuration_Error);
            } else {
                throw e;
            }
        } finally {
            PJN_PublishTransactionLog.publish();
        }

        return deserializeResponse;
    }

    /**
     * Builds HTTP Request for our current API method
     * @param forceNewToken Defines if needs a new Authorization token
     * @param body          HTTP Request body
     * @returns `HttpRequest`
     */
    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    private HttpRequest buildCalloutRequest(Boolean forceNewToken, String body) {
        String authToken = getConnectionAuthorizationToken(false);

        HttpRequest req = networkCalloutSettings.getRequest(body);
        req.setHeader('Authorization', authToken);

        return req;
    }

    /**
     * Get Veeva Network connection authotization token needed on each Veeva Network call
     * @param forceNewToken Force new authorization token instead of using existing
     * @returns `String`
     */
    private static String getConnectionAuthorizationToken(Boolean forceNewToken) {
        PJN_NetworkAuth networkAuth = new PJN_NetworkAuth(forceNewToken);

        String sessionAuthToken = networkAuth.getAuthToken();

        if (String.isNotBlank(sessionAuthToken)) {
            return sessionAuthToken;
        }

        HttpRequest req = networkAuth.getAuthTokenRequest();

        PJN_NetworkResponse deserializeResponse = doCallout(req);
        PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(PJN_PublishTransactionLog.convertHttpRequest(req), System.JSON.serialize(deserializeResponse));
        PJN_PublishTransactionLog.addDebug(transactionLog);
        checkForNetworkErrors(deserializeResponse);

        if(deserializeResponse != null && deserializeResponse.responseStatus == PJN_NetworkConstants.NETWORK_SUCCESS) {
            networkAuth.saveAuthToken(deserializeResponse.sessionId);
        }

        return networkAuth.getAuthToken();
    }

    /**
     * Do the actual callout to Veeva Network
     * @param req   HTTP Request for callout
     * @returns `Map<String, Object>`
     */
    private static PJN_NetworkResponse doCallout(HttpRequest req) {
        Http h = new Http();
        PJN_NetworkResponse deserializeResponse;

        if (noRunInTest) {
            return deserializeResponse;
        }

        try {
            HttpResponse res = h.send(req);
            System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::doCallout response: ' + res.getBody());
            deserializeResponse = new PJN_NetworkResponse((Map<String, Object>) JSON.deserializeUntyped(res.getBody()));
        } catch (Exception e) {
            throw e;
        }
        return deserializeResponse;
    }

    /**
     * Verify Veeva Network connection issues
     * @param deserializeResponse   Veeva Network response deserialized from JSON to Map
     * @returns `List<String>`  List of error messages
     * @exception
     */
    public static List<String> checkForNetworkErrors(PJN_NetworkResponse deserializeResponse) {
        List<String> errors = new List<String>();

        if (deserializeResponse == null) {
            return errors;
        }

        Boolean isNotSuccessWithErrors = deserializeResponse.responseStatus != PJN_NetworkConstants.NETWORK_SUCCESS
            && deserializeResponse.errors != null;

        if (isNotSuccessWithErrors) {
            for (PJN_NetworkError networkError : deserializeResponse.errors) {
                String errorMessage = PJN_NetworkStatusMapping.getMessageForNetwokStatus(networkError.type);

                if (String.isBlank(errorMessage)) {
                    errorMessage = networkError.message;
                }

                if (String.isBlank(errorMessage)) {
                    continue;
                }

                errors.add(errorMessage);
            }

            if (errors.isEmpty() && String.IsNotBlank(deserializeResponse.responseMessage)) {
                errors.add(deserializeResponse.responseMessage);
            }
        }

        Boolean isPartiallySuccessful = deserializeResponse.responseStatus == PJN_NetworkConstants.NETWORK_PARTIAL_SUCCESS;

        storePartialSuccessfulErrors(isPartiallySuccessful, errors);

        if (!errors.isEmpty() && !isPartiallySuccessful) {
            System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Exception - ' + 'Label.PJN_Network_Connection_Error' + '.');
            // throw new NetworkCalloutException('Label.PJN_Network_Connection_Error' + ': '+String.join(errors,',\n'));
        }

        return errors;
    }

    /**
     * Store Partial success errors
     * @param isPartiallySuccessful Is Partial Success active?
     * @param errors                List of errors
     */
    private static void storePartialSuccessfulErrors(Boolean isPartiallySuccessful, List<String> errors) {
        if(isPartiallySuccessful) {
            System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Partial Success'+ String.join(errors, '\n'));

            if(partialSuccessErrors == null) {
                partialSuccessErrors = new List<String>();
            }

            partialSuccessErrors.addAll(errors);
        }
    }
}