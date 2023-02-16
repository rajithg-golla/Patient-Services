/**
 * Create and Publish Transaction logs
 * @author  Mavens
 * @group   DEBUG
 */
public without sharing class PJN_PublishTransactionLog {

    public static String logType;

    private static List<PJN_Transaction_Log__e> transactionLogs;

    public static PJN_Transaction_Log__e buildCalloutLog(String calloutRequest, String calloutResponse) {
        return new PJN_Transaction_Log__e(
            PJN_Callout_Request__c = truncate(calloutRequest, 4000),
            PJN_Callout_Response__c = truncate(calloutResponse, 4000),
            PJN_Running_User__c = UserInfo.getUserId(),
            PJN_Type__c = String.IsNotBlank(logType) ? logType : 'Callout'
        );
    }

    public static PJN_Transaction_Log__e buildURLLog(String incomingUrl) {
        return new PJN_Transaction_Log__e(
            PJN_Incoming_URL__c = truncate(incomingUrl, 4000),
            PJN_Running_User__c = UserInfo.getUserId(),
            PJN_Type__c = String.IsNotBlank(logType) ? logType : 'URL'
        );
    }

    public static void addDebug(PJN_Transaction_Log__e transactionLog) {
        transactionLog.PJN_Level__c = 'Debug';

        if (transactionLogs == null) {
            transactionLogs = new List<PJN_Transaction_Log__e>();
        }

        transactionLogs.add(transactionLog);
    }

    public static void addError(PJN_Transaction_Log__e transactionLog) {
        transactionLog.PJN_Level__c = 'Error';

        if (transactionLogs == null) {
            transactionLogs = new List<PJN_Transaction_Log__e>();
        }

        transactionLogs.add(transactionLog);
    }

    public static void publish() {
        if (transactionLogs == null || transactionLogs.isEmpty()) {
            return;
        }

        List<Database.SaveResult> results = EventBus.publish(transactionLogs);
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'DEBUG::Error returned: ' +
                                err.getStatusCode() +
                                ' - ' +
                                err.getMessage());
                }
            }
        }
    }

    public static String convertHttpRequest(HttpRequest request) {
        Map<String, Object> requestHeader = new Map<String, Object> {
            'Accept' => request.getHeader('Accept'),
            'Location' => request.getHeader('Location'),
            'Content-Type' => request.getHeader('Content-Type')
        };

        Map<String, Object> requestAsMap = new Map<String, Object> {
            'Header' => requestHeader,
            'Body' => request.getBody(),
            'Endpoint' => request.getEndpoint(),
            'Method' => request.getMethod()
        };

        return System.JSON.serialize(requestAsMap);
    }

    /**
    * @description returns a cleaned up string, not null and length cut
    * @param String stringToTruncate
    * @param Integer stringMaxLength
    * @return String cleanedString
    */
    private static String truncate(String stringToTruncate, Integer stringMaxLength) {
    if(stringToTruncate != null && stringToTruncate.length() > stringMaxLength) {
        stringToTruncate = stringToTruncate.left(stringMaxLength);
    }

    return stringToTruncate;
}
}