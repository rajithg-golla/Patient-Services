/**
 * @author Mavens
 * @author Utility methods used by CRM Connection callouts.
 */
public without sharing class PJN_VeevaCRMConnectionUtility {

    /**
     * This is a generic method that takes in call method, endpoint and body to make a Http callout
     * @param callMethod
     * @param callEndPoint
     * @param callBody
     * @returns `HTTPResponse`
     */
    public static HTTPResponse calloutRemoteCrm(String callMethod, String callEndPoint, String callBody){
        try {

            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(callEndPoint);
            req.setMethod(callMethod);
            if (callBody != null){
                req.setBody(callBody);
            }

            System.debug('req: ' + req);

            // send the request
            HTTPResponse res = (new Http()).send(req);

            return res;
        } catch(Exception callException) {
            System.debug(callException);
        }

        return null;
    }

    /**
     * Serialize the objects and update keys to match SObject names.
     * @param objects
     * @returns `String`
     */
    public static String createJsonString(List<Object> objects) {
        String result = JSON.serialize(new Map<String, Object>{'records' => objects});
        result = result.replace('_c"', '__c"').replace('_r"', '__r"').replace('___', '__');
        return result;
    }

    /**
     * Overloaded method that will call calloutRemoteCrm with 3 parameters.
     * @param callMethod
     * @param callEndPoint
     * @returns `HTTPResponse`
     */
    public static HTTPResponse calloutRemoteCrm(String callMethod, String callEndPoint){
        return calloutRemoteCrm(callMethod, callEndPoint, NULL);
    }

    /**
     * This is a generic method that takes in a HttpResponse and deserializes both success and error responses.
     * @param response
     * @returns `Map<String, Object>`
     */
    public static Map<String, Object> deserializeJson(String response) {

        Map<String, Object> deserializedResponse = new Map<String, Object>();
        if (String.IsNotBlank(response)){
            try{
                Object calloutJsonResponse = JSON.deserializeUntyped(response);

                // Checks if it is a query success response.
                if(calloutJsonResponse instanceOf Map<String, Object>){
                    deserializedResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
                } else {
                    List<Object> deserializedResultList = (List<Object>) JSON.deserializeUntyped(response);
                    Boolean isErrorResponse = resultListHasError(deserializedResultList);

                    if(!isErrorResponse) {
                        //Convert to a map for consistency
                        deserializedResponse.put('results',deserializedResultList);
                    }
                }
            } catch(Exception deserializedException) {
                System.debug(LoggingLevel.ERROR, deserializedException.getMessage());
            }
        }
        return deserializedResponse;
    }

    /**
     * Checks for generic, major errors like auth issues that error out the entire call.
     * @param deserializedResultList
     * @returns `Boolean`
     */
    private static Boolean resultListHasError(List<Object> deserializedResultList) {
        Boolean isErrorResponse = false;
        for(Object deserializedError : deserializedResultList){
            Map<String, Object> result = (Map<String, Object>)deserializedError;
            if(result.containsKey('success') && result.get('success')==false) {
                isErrorResponse = true;
                //parse and collect full message, it could be nested
                String errMsg = '';
                for(Object error : (List<Object>)result.get('errors')){
                    Map<String, Object> errorResult = (Map<String, Object>)error;
                    errMsg += (String)errorResult.get('statusCode') + ': ' + ((String)errorResult.get('message')).normalizeSpace() + '\n';
                }
                System.debug(LoggingLevel.ERROR, errMsg);
            }
        }
        return isErrorResponse;
    }

    /**
     * Does the result contain the reference Id
     * @param insertResult
     * @returns `Boolean`
     */
    public static Boolean resultHasId(Map<String, Object> insertResult) {
        return insertResult.containsKey('referenceId') && insertResult.get('referenceId') != NULL;
    }

    /**
     * Build a url encoded list of strings to pass to CRM in get call.
     * @param stringList
     * @returns `String`
     */
    public static String urlEncodedStringList(List<String> stringList) {
        String result = '%27';

        for (String currentString : stringList) {
            result += currentString + '%27%2C';
        }

        result = result.removeEnd('%2C');

        return result;
    }
}