/**
 * @author      Mavens
 * @group       DataLake
 * @description Mock Data for MVN_DataLakeCMUpdateBatchSch
 */
@IsTest
public with sharing class MVN_DataLakeCMUpdateBatchSchMock {
    public class SearchSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            Map<String, Object> requestBody = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
            String query = String.valueOf(requestBody.get('query'));
            if(query.contains('data_semarchy_cm_pub_m_hcp_profile')) {
                responseBody = getHCPRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_m_hco_profile')) {
                responseBody = getHCORetrieveSuccessResponseBody();
            }

            return buildResponse(responseBody);
        }
    }

    private static HTTPResponse buildResponse(String jsonBody) {
        HTTPResponse response = new HTTPResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody(jsonBody);

        return response;
    }

    private static String getHCPRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCPEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCORetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
                getHCOEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 100; eIndex++) {
            Integer npi = 1234567100 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_id": ' + eIndex +',' +
                '"hcp_npi_id": "' + npi + '",' +
                '"hcp_create_date":"2021-05-09 17:12:20.000",' +
                '"hcp_update_date":"2021-05-09 17:12:20.000",' +
                '"hcp_provider":"VEEVA",' +
                '"hcp_reg_hcp_id":"REGP123123123",' +
                '"hcp_salutation": "",' +
                '"hcp_first_name":"JOHN",' +
                '"hcp_last_name":"SMITH' + eIndex + '",' +
                '"hcp_ama_no_contact_cd":"FALSE",' +
                '"hcp_pdrp_flag":"0",' +
                '"hcp_title_type_desc" : "Medical Assistant",' +
                '"hcp_title_type_cd" : "MEAS",' +
                '"hcp_status_type_desc" : "Active",' +
                '"hcp_status_type_cd" : "A",' +
                '"hcp_type_desc" : "PRESCRIBER",' +
                '"hcp_type_cd" : "PRES",' +
                '"hcp_active_flag" : "Y",' +
                '"hcp_reg_id" : "REG171018172"' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 100; eIndex++) {
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_is_teaching_hospital" : "false",' +
                '"hco_cot_type_desc" : "Clinic",' +
                '"hco_cot_type_cd" : "CL6100",' +
                '"hco_status_type_desc" : "Active",' +
                '"hco_status_type_cd" : "A",' +
                '"hco_type_desc" : "Clinic - Independently Owned",' +
                '"hco_type_cd" : "CIO",' +
                '"hco_valid_status" : "Y",' +
                '"hco_name" : "MAVENS HEALTH CLINIC' + eIndex + '",' +
                '"hco_reg_id" : "REGO987987987",' +
                '"hco_provider" : "VEEVA",' +
                '"hco_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_id" : 100' + eIndex +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }
}