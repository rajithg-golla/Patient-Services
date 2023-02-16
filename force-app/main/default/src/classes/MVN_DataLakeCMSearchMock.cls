/**
 * @author      Mavens
 * @group       DataLake
 * @description Mock responses for MVN_DataLakeCMSearchHdlr
 */
@IsTest
public with sharing class MVN_DataLakeCMSearchMock {
    public class SearchSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            Map<String, Object> requestBody = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
            String query = String.valueOf(requestBody.get('query'));
            if(query.contains('data_semarchy_cm_pub_m_hcp_profile')) {
                responseBody = getHCPRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_m_hco_profile')) {
                responseBody = getHCORetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_address')) {
                responseBody = getAddressRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hco_hcp_affiliation')) {
                responseBody = getAffilaitionRetrieveSuccessResponseBody(query);
            } else if (query.contains('data_semarchy_cm_pub_x_hcp_email')) {
                responseBody = getHCPEmailRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hco_email')) {
                responseBody = getHCOEmailRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hcp_phone')) {
                responseBody = getHCPPhoneRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hco_phone')) {
                responseBody = getHCOPhoneRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hco_hco_affiliation')) {
                responseBody = getHCOAffiliationRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hcp_license')) {
                responseBody = getHCPLicenseRetrieveSuccessResponseBody();
            } else if (query.contains('data_semarchy_cm_pub_x_hcp_specialty')) {
                responseBody = getHCPSpecialtyRetrieveSuccessResponseBody();
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

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;

            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_id": 123123123' + currentEntityId +',' +
                '"hcp_create_date":"2021-05-09 17:12:20.000",' +
                '"hcp_update_date":"2021-05-09 17:12:20.000",' +
                '"hcp_provider":"VEEVA",' +
                '"hcp_reg_hcp_id":"REGP123123123",' +
                '"hcp_salutation": "",' +
                '"hcp_first_name":"JOHN",' +
                '"hcp_last_name":"SMITH",' +
                '"hcp_ama_no_contact_cd":"FALSE",' +
                '"hcp_pdrp_flag":"0",' +
                '"hcp_title_type_desc" : "Medical Assistant",' +
                '"hcp_title_type_cd" : "MEAS",' +
                '"hcp_status_type_desc" : "Active",' +
                '"hcp_status_type_cd" : "A",' +
                '"hcp_type_desc" : "NON-PRESCRIBER",' +
                '"hcp_type_cd" : "NON-PRES",' +
                '"hcp_active_flag" : "Y",' +
                '"hcp_reg_id" : "REG171018172"' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;

            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_is_teaching_hospital" : "false",' +
                '"hco_cot_type_desc" : "Clinic",' +
                '"hco_cot_type_cd" : "CL6100",' +
                '"hco_status_type_desc" : "Active",' +
                '"hco_status_type_cd" : "A",' +
                '"hco_type_desc" : "Clinic - Independently Owned",' +
                '"hco_type_cd" : "CIO",' +
                '"hco_valid_status" : "Y",' +
                '"hco_name" : "MAVENS HEALTH CLINIC",' +
                '"hco_reg_id" : "REGO987987987",' +
                '"hco_provider" : "VEEVA",' +
                '"hco_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_id" : 123123123' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getAddressRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
                getAddressEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getAddressEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;

            entitiesForRetrieveSuccessResponseBody += '{' +
                '"addr_usps_validated_status" : "Y",' +
                '"addr_valid_status" : "Y",' +
                '"addr_residential_delivery_indi" : "Commercial",' +
                '"addr_record_type" : "S",' +
                '"addr_longitude" : -107.32516,' +
                '"addr_latitude" : 39.54451,' +
                '"addr_postal_zip_code4" : "3601",' +
                '"addr_postal_zip_code" : "81601",' +
                '"addr_state" : "CO",' +
                '"addr_city" : "GLENWOOD SPRINGS",' +
                '"addr_address_line1" : "919 GRAND AVE",' +
                '"addr_provider" : "BEGHOU",' +
                '"addr_update_date" : "2021-05-09 17:12:20.000",' +
                '"addr_create_date" : "2021-05-09 17:12:20.000",' +
                '"addr_id" : 456456456' + currentEntityId +',' +
                '"parent_id" : 123123123' + currentEntityId +',' +
                '"primary_addr_ind" : "0"' +
              '}, {' +
                '"addr_valid_status" : "Y",' +
                '"addr_longitude" : -106.0939,' +
                '"addr_latitude" : 39.59029,' +
                '"addr_postal_zip_code" : "80443",' +
                '"addr_state" : "CO",' +
                '"addr_city" : "FRISCO",' +
                '"addr_address_line2" : "SUIT 103",' +
                '"addr_address_line1" : "984 N TEN MILE DR",' +
                '"addr_provider" : "BEGHOU",' +
                '"addr_update_date" : "2021-05-09 17:12:20.000",' +
                '"addr_create_date" : "2021-05-09 17:12:20.000",' +
                '"addr_id" : 456456457' + currentEntityId +',' +
                '"parent_id" : 123123123' + currentEntityId +',' +
                '"primary_addr_ind" : "0"' +
              '}, {' +
                '"addr_usps_validated_status" : "Y",' +
                '"addr_valid_status" : "Y",' +
                '"addr_record_type" : "H",' +
                '"addr_longitude" : -106.62489,' +
                '"addr_latitude" : 39.63769,' +
                '"addr_postal_zip_code4" : "5525",' +
                '"addr_postal_zip_code" : "81632",' +
                '"addr_state" : "CO",' +
                '"addr_city" : "EDWARDS",' +
                '"addr_address_line2" : "STE B200",' +
                '"addr_address_line1" : "1140 EDWARDS VILLAGE BLVD STE B200",' +
                '"addr_provider" : "BEGHOU",' +
                '"addr_update_date" : "2021-05-09 17:12:20.000",' +
                '"addr_create_date" : "2021-05-09 17:12:20.000",' +
                '"addr_id" : 456456458' + currentEntityId +',' +
                '"parent_id" : 123123123' + currentEntityId +',' +
                '"primary_addr_ind" : "1"' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getAffilaitionRetrieveSuccessResponseBody(String query) {
        return '{' +
            '"Items": [' +
                getAffiliationEntitiesForRetrieveSuccessResponseBody(query) +
            ']' +
        '}';
    }

    private static String getAffiliationEntitiesForRetrieveSuccessResponseBody(String query) {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            String hcpId = query.contains('hco_hcp_affiliation_hcp_id') ?
                '123123123' + currentEntityId :
                '12345678902';
            String hcoId = query.contains('hco_hcp_affiliation_hco_id') ?
                '123123123' + currentEntityId :
                '12345678901';

            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_hcp_affiliation_hcp_id" : ' + hcpId +',' +
                '"hco_hcp_affiliation_hco_id" : ' + hcoId +',' +
                '"hco_hcp_affiliation_type_cd" : "P2B",' +
                '"hco_hcp_affiliation_primary_ind" : "Y",' +
                '"hco_hcp_affiliation_status" : "Y",' +
                '"hco_hcp_affiliation_provider" : "VEEVA",' +
                '"hco_hcp_affiliation_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_hcp_affiliation_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_hcp_affiliation_id" : 123412341' + currentEntityId +'' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCPEmailRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
                getHCPEmailEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPEmailEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_email_hcp_id" : 123123123' + currentEntityId +',' +
                '"hcp_email_type_desc" : "EMAIL",' +
                '"hcp_email_type_cd" : "EM",' +
                '"hcp_email_valid_status" : "Y",' +
                '"hcp_email_standard_email" : "test@test.com",' +
                '"hcp_email_provider" : "BEGHOU",' +
                '"hcp_email_update_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_email_create_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_email_id" : 234523452' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOEmailRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCOEmailEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCOEmailEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_email_hco_id" : 123123123' + currentEntityId +',' +
                '"hco_email_type_desc" : "EMAIL",' +
                '"hco_email_type_cd" : "EM",' +
                '"hco_email_valid_status" : "Y",' +
                '"hco_email_standard_email" : "test@test.com",' +
                '"hco_email_provider" : "BEGHOU",' +
                '"hco_email_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_email_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_email_id" : 234523452' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCPPhoneRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
                getHCPPhoneEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPPhoneEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_phone_hcp_id" : 123123123' + currentEntityId + ',' +
                '"hcp_phone_type_desc" : "OFFICE FAX",' +
                '"hcp_phone_type_cd" : "OF",' +
                '"hcp_phone_valid_status" : "Y",' +
                '"hcp_phone_standard_phone_num" : "7742372130",' +
                '"hcp_phone_provider" : "LASH",' +
                '"hcp_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_id" : 12012012' + currentEntityId +
            '}, {' +
                '"hcp_phone_hcp_id" : 123123123' + currentEntityId + ',' +
                '"hcp_phone_type_desc" : "OFFICE PHONE",' +
                '"hcp_phone_type_cd" : "OP",' +
                '"hcp_phone_valid_status" : "Y",' +
                '"hcp_phone_standard_phone_num" : "5089941400",' +
                '"hcp_phone_provider" : "BEGHOU",' +
                '"hcp_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_id" : 12012013' + currentEntityId +
            '}, {' +
                '"hcp_phone_hcp_id" : 123123123' + currentEntityId + ',' +
                '"hcp_phone_type_desc" : "PHONE",' +
                '"hcp_phone_type_cd" : "PH",' +
                '"hcp_phone_valid_status" : "Y",' +
                '"hcp_phone_standard_phone_num" : "5088235536",' +
                '"hcp_phone_provider" : "BEGHOU",' +
                '"hcp_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_id" : 12012014' + currentEntityId +
            '}, {' +
                '"hcp_phone_hcp_id" : 123123123' + currentEntityId + ',' +
                '"hcp_phone_type_desc" : "FAX",' +
                '"hcp_phone_type_cd" : "FX",' +
                '"hcp_phone_valid_status" : "Y",' +
                '"hcp_phone_standard_phone_num" : "5089102212",' +
                '"hcp_phone_provider" : "BEGHOU",' +
                '"hcp_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hcp_phone_id" : 12012015' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOPhoneRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCOPhoneEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCOPhoneEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_phone_hco_id" : 123123123' + currentEntityId + ',' +
                '"hco_phone_type_desc" : "OFFICE FAX",' +
                '"hco_phone_type_cd" : "OF",' +
                '"hco_phone_valid_status" : "Y",' +
                '"hco_phone_standard_phone_num" : "7742372130",' +
                '"hco_phone_provider" : "LASH",' +
                '"hco_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_id" : 12012012' + currentEntityId +
            '}, {' +
                '"hco_phone_hco_id" : 123123123' + currentEntityId + ',' +
                '"hco_phone_type_desc" : "OFFICE PHONE",' +
                '"hco_phone_type_cd" : "OP",' +
                '"hco_phone_valid_status" : "Y",' +
                '"hco_phone_standard_phone_num" : "5089941400",' +
                '"hco_phone_provider" : "BEGHOU",' +
                '"hco_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_id" : 12012013' + currentEntityId +
            '}, {' +
                '"hco_phone_hco_id" : 123123123' + currentEntityId + ',' +
                '"hco_phone_type_desc" : "PHONE",' +
                '"hco_phone_type_cd" : "PH",' +
                '"hco_phone_valid_status" : "Y",' +
                '"hco_phone_standard_phone_num" : "5088235536",' +
                '"hco_phone_provider" : "BEGHOU",' +
                '"hco_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_id" : 12012014' + currentEntityId +
            '}, {' +
                '"hco_phone_hco_id" : 123123123' + currentEntityId + ',' +
                '"hco_phone_type_desc" : "FAX",' +
                '"hco_phone_type_cd" : "FX",' +
                '"hco_phone_valid_status" : "Y",' +
                '"hco_phone_standard_phone_num" : "5089102212",' +
                '"hco_phone_provider" : "BEGHOU",' +
                '"hco_phone_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_phone_id" : 12012015' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOAffiliationRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCOAffiliationEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCOAffiliationEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hco_hco_affiliation_hco_id_child" : 1234567890,' +
                '"hco_hco_affiliation_hco_id_parent" : 123123123' + currentEntityId +',' +
                '"hco_hco_affiliation_type_cd" : "P2B",' +
                '"hco_hco_affiliation_primary_ind" : "Y",' +
                '"hco_hco_affiliation_status" : "Y",' +
                '"hco_hco_affiliation_provider" : "VEEVA",' +
                '"hco_hco_affiliation_update_date" : "2021-05-09 17:12:20.000",' +
                '"hco_hco_affiliation_create_date" : "2021-05-09 17:12:20.000",' +
                '"hco_hco_affiliation_id" : 123412342' + currentEntityId +'' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCPLicenseRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCPLicenseEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPLicenseEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_license_id": 1741119' + currentEntityId + ',' +
                '"hcp_license_create_date": "2021-05-09 17:12:20.000",' +
                '"hcp_license_update_date": "2021-05-09 17:12:20.000",' +
                '"hcp_license_state_cd": "TX",' +
                '"hcp_license_provider": "MEDPRO",' +
                '"hcp_license_state_license_num": "PA08016",' +
                '"hcp_license_expiration_date": "2022-08-31",' +
                '"hcp_license_status": "ACTIVE",' +
                '"hcp_license_adj_expiration_date": "2022-08-31",' +
                '"hcp_license_hcp_id": 123123123' + currentEntityId +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCPSpecialtyRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getHCPSpecialtyEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPSpecialtyEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"hcp_spec_id": 23570835' + currentEntityId + ',' +
                '"hcp_spec_create_date": "2021-05-09 17:12:20.000",' +
                '"hcp_spec_update_date": "2021-05-09 17:12:20.000",' +
                '"hcp_spec_provider": "VEEVA",' +
                '"hcp_spec_type": "DERMATOLOGY",' +
                '"hcp_spec_valid_status": "Y",' +
                '"hcp_specialty_type_cd": "DERMATOLOGY",' +
                '"hcp_specialty_type_desc": "DERMATOLOGY",' +
                '"hcp_spec_hcp_id": 123123123' + currentEntityId + ',' +
                '"hcp_spec_rank": "1"' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }
}