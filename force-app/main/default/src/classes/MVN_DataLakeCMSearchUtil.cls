/**
 * @author      Mavens
 * @group       DataLake
 * @description DataLake Search Utility
 */
public with sharing class MVN_DataLakeCMSearchUtil {

    /**
     * MDM Connection
     */
    private static MVN_MDM_Connection__mdt mdmConnection = MVN_MDMConnectionUtil.getConnectionByName('MVN_DataLake_CM');

    /**
     * DATALAKE Environment
     */
    public static String DATALAKE_ENVIRONMENT = mdmConnection != null && String.IsNotBlank(mdmConnection.MVN_Environment__c) ?
        mdmConnection.MVN_Environment__c + '.' :
        '';

    /**
     * DataLake Search limit
     */
    public static final Integer DATALAKE_SEARCH_LIMIT = 25;

    /**
     * Status mapping from DataLake to SFDC
     */
    private static final Map<String, String> STATUS_FROM_DATALAKE_MAPPING = new Map<String, String> {
        'y' => 'A',
        'n' => 'I'
    };

    /**
     * Complete Status mapping from DataLake to SFDC
     */
    private static final Map<String, String> COMPLETE_STATUS_FROM_DATALAKE_MAPPING = new Map<String, String> {
        'y' => 'Active',
        'n' => 'Inactive'
    };

    /**
     * Status mapping from SFDC to DataLake
     */
    private static final Map<String, String> STATUS_TO_DATALAKE_MAPPING = new Map<String, String> {
        'a' => 'Y',
        'i' => 'N',
        'active' => 'Y',
        'inactive' => 'N'
    };

    /**
     * Get DataLake Request using query for the body
     * @param query Query which will obtain AWS Lambda to send into Athena
     * @return  `HttpRequest`
     */
    public static HttpRequest getDataLakeRequest(String query) {
        HttpRequest req = new HttpRequest();
        String thisEndpoint = 'callout:MVN_DataLake_API/search';
        req.setEndpoint(thisEndpoint);
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setHeader('x-api-key', '{!$Credential.Password}');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        Map<String, String> body = new Map<String, String> {
            'query' => query
        };
        req.setBody(System.JSON.serialize(body));
        return req;
    }

    /**
     * Call DataLake sending request body to corresponding endpoint
     * @param request   DataLake Request
     * @return  `Map<String, Object>`
     */
    public static Map<String, Object> callDataLake(HttpRequest request) {
        Http h = new Http();
        HttpResponse response = h.send(request);
        Map<String, Object> datalakeResponse = (Map<String, Object>) System.JSON.deserializeUntyped(response.getBody());
        if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            System.debug('### Datalake:CM:Search::HTTP Error response: ' + response);
            System.debug('### Datalake:CM:Search::DataLake Error: ' + datalakeResponse);
        }
        return datalakeResponse;
    }

    /**
     * Get Status from DataLake to SFDC mapped
     * @param fieldValue    DataLake Status value
     * @return  `String`
     */
    public static String getStatusFromMapped(String fieldValue) {
        return String.isNotBlank(fieldValue) && STATUS_FROM_DATALAKE_MAPPING.containsKey(fieldValue.toLowerCase()) ?
            STATUS_FROM_DATALAKE_MAPPING.get(fieldValue.toLowerCase()) :
            'A';
    }

    /**
     * Get Complete Status from DataLake to SFDC mapped
     * @param fieldValue    DataLake Status value
     * @return  `String`
     */
    public static String getCompleteStatusFromMapped(String fieldValue) {
        return String.isNotBlank(fieldValue) && COMPLETE_STATUS_FROM_DATALAKE_MAPPING.containsKey(fieldValue.toLowerCase()) ?
            COMPLETE_STATUS_FROM_DATALAKE_MAPPING.get(fieldValue.toLowerCase()) :
            'Active';
    }

    /**
     * Get String value from populated fields
     * @param fieldName Field name
     * @return  `String`
     */
    public static String getStringValue(Map<String, Object> reqPopulatedFields, String fieldName) {
        if (String.isBlank(fieldName) || reqPopulatedFields == null || reqPopulatedFields.isEmpty()) {
            return null;
        }
        return reqPopulatedFields.containsKey(fieldName.toLowerCase()) ?
            String.valueOf(reqPopulatedFields.get(fieldName.toLowerCase())) :
            null;
    }

    /**
     * Get Datetime value from populated field
     * @param fieldName Field Name
     * @return  `Datetime`
     */
    public static Datetime getDatetimeValue(Map<String, Object> reqPopulatedFields, String fieldName) {
        if (String.isBlank(fieldName) || reqPopulatedFields == null || reqPopulatedFields.isEmpty()) {
            return null;
        }
        return reqPopulatedFields.containsKey(fieldName.toLowerCase()) ?
            Datetime.valueOf(reqPopulatedFields.get(fieldName.toLowerCase())) :
            null;
    }

    /**
     * Get Date value from populated field
     * @param reqPopulatedFields    Populated fields
     * @param fieldName             Field Name
     * @return  `Date`
     */
    public static Date getDateValue(Map<String, Object> reqPopulatedFields, String fieldName) {
        if (String.isBlank(fieldName) || reqPopulatedFields == null || reqPopulatedFields.isEmpty()) {
            return null;
        }
        return reqPopulatedFields.containsKey(fieldName.toLowerCase()) ?
            Date.valueOf(reqPopulatedFields.get(fieldName.toLowerCase())) :
            null;
    }

    /**
     * Get String Value mapped from populated field
     * @param reqPopulatedFields    Populated fields
     * @param fieldName             Field Name
     * @param valueMapping          Value Mappings
     * @return  `String`
     */
    public static String getStringValueMapped(Map<String, Object> reqPopulatedFields, String fieldName, Map<String, String> valueMapping) {
        String fieldValue = getStringValue(reqPopulatedFields, fieldName);
        if (String.IsNotBlank(fieldValue) && valueMapping != null && !valueMapping.isEmpty()) {
            fieldValue = valueMapping.containsKey(fieldValue.toLowerCase()) ?
                valueMapping.get(fieldValue.toLowerCase()) :
                null;
        }
        return fieldValue;
    }

    /**
     * Get String value mapped with default value if null
     * @param fieldValue    Field Value to map
     * @param valueMapping  Value Mapping
     * @param defaultValue  Default value if null
     * @return  `String`
     */
    public static String getStringValueMappedWithDefault(String fieldValue, Map<String, String> valueMapping, String defaultValue) {
        return String.isNotBlank(fieldValue) && valueMapping != null && valueMapping.containsKey(fieldValue.toLowerCase()) ?
            valueMapping.get(fieldValue.toLowerCase()) :
            defaultValue;
    }

    /**
     * Get Field Filter for field and value provided
     * @param fieldName     Field Name in DataLake to filter
     * @param fieldValue    Field value in DataLake to filter
     * @return  `String`
     */
    public static String getFieldFilter(String fieldName, String fieldValue) {
        String action = fieldValue.contains('*') ? 'LIKE' : '=';
        fieldValue = fieldValue.replaceAll('\\*', '%');
        return 'Upper(' + fieldName + ') ' + action + ' Upper(\'' + fieldValue + '\') AND ';
    }
}