/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Mock data for PJN_NetworkSearchHdlr
 */
public with sharing class PJN_NetworkSearchHdlrMock {
    public class SearchSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            if(req.getEndpoint().toLowerCase().contains('/auth')) {
                responseBody =
                '{"responseStatus":"SUCCESS","sessionId":"newSession12345"}';
            } else if (req.getEndpoint().toLowerCase().contains('hcp')) {
                responseBody = getHCPRetrieveSuccessResponseBody();
            } else if (req.getEndpoint().toLowerCase().contains('hco')) {
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
            '"responseStatus": "SUCCESS",' +
            '"entities": [' +
            getHCPEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCORetrieveSuccessResponseBody() {
        return '{' +
            '"responseStatus": "SUCCESS",' +
            '"entities": [' +
                getHCOEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getHCPEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';

        for (Integer eIndex = 0; eIndex < 10; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;

            entitiesForRetrieveSuccessResponseBody += '{' +
                '"entityId": "93358025901211' + currentEntityId + '",' +
                '"entityType": "HCP",' +
                '"metaData": {},' +
                '"entity": {' +
                    '"title__c": "Key Account Manager",' +
                    '"record_owner_type__v": "LOCAL",' +
                    '"status__c": "A",' +
                    '"employee_business_unit__c": "Sales",' +
                    '"employee_number__c": "103",' +
                    '"last_name__v": "Carter",' +
                    '"record_delta_id__v": "933580259060776959",' +
                    '"record_owner_name__v": "Local",' +
                    '"employee_name__c": "Daniel Carter",' +
                    '"primary_country__v": "US",' +
                    '"created_date__v": "2018-12-07T08:11:33.000Z",' +
                    '"first_name__v": "Daniel",' +
                    '"employee_hire_date__c": "2018-12-01",' +
                    '"is_veeva_master__v": false,' +
                    '"status_update_time__v": "2018-12-07T08:11:33.000Z",' +
                    '"modified_date__v": "2018-12-07T08:11:33.000Z",' +
                    '"record_state__v": "VALID",' +
                    '"hcp_type__v": "P",' +
                    '"candidate_record__v": false,' +
                    '"record_version__v": 0,' +
                    '"vid__v": "93358025901211' + currentEntityId + '",' +
                    '"is_externally_mastered__v": false,' +
                    '"licenses__v":[ ' +
                        '{ ' +
                            '"primary_license__c":"U",' +
                            '"primary_license__c_value__u":"Unknown/No response",' +
                            '"address_vid__v":"93291072424496' + currentEntityId + '",' +
                            '"record_owner_type__v":"LOCAL",' +
                            '"record_owner_type__v_value__u":"Locally Managed",' +
                            '"effective_date__v":"2010-05-05",' +
                            '"license_number__v":"1256987",' +
                            '"status_update_time__v":"2018-08-10T19:20:09.000Z",' +
                            '"record_delta_id__v":"932910724760764416",' +
                            '"license_status__v":"A",' +
                            '"license_status__v_value__u":"Active",' +
                            '"entity_type__v":"HCP",' +
                            '"entity_type__v_value__u":"Health Care Professional",' +
                            '"record_owner_name__v":"Local",' +
                            '"expiration_date__v":"2013-12-31",' +
                            '"body__v":"ALMD",' +
                            '"modified_date__v":"2018-08-10T19:20:11.000Z",' +
                            '"record_state__v":"VALID",' +
                            '"record_state__v_value__u":"Valid",' +
                            '"license_status_condition__v":"0",' +
                            '"license_status_condition__v_value__u":"No Known Conditions",' +
                            '"license_subtype__v":"U",' +
                            '"license_subtype__v_value__u":"Unlimited",' +
                            '"vid__v":"93291072424496' + currentEntityId + '",' +
                            '"entity_vid__v":"93291072424372' + currentEntityId + '",' +
                            '"created_date__v":"2018-08-10T19:20:09.000Z",' +
                            '"is_veeva_master__v":false,' +
                            '"entity_type__u":"LICENSE",' +
                            '"object_name__u":"LICENSE",' +
                            '"address_vid__v_value__u":"326 Harolds DR BISMARCK ND 58501"' +
                        '}' +
                    '],' +
                    '"addresses__v": [' +
                        '{' +
                            '"nwk_primary_address__c": "Y",' +
                            '"address_line_1__v": "200 Park Blvd.",' +
                            '"record_owner_type__v": "LOCAL",' +
                            '"record_delta_id__v": "933580259020275711",' +
                            '"record_owner_name__v": "Local",' +
                            '"locality__v": "San Diego",' +
                            '"country__v": "US",' +
                            '"created_date__v": "2018-12-07T08:11:33.000Z",' +
                            '"is_veeva_master__v": false,' +
                            '"status_update_time__v": "2018-12-07T08:11:33.000Z",' +
                            '"address_type__v": "P",' +
                            '"entity_type__v": "EMPLOYEE__C",' +
                            '"address_verification_status__v": "DS",' +
                            '"address_status__v": "A",' +
                            '"modified_date__v": "2018-12-07T08:11:33.000Z",' +
                            '"record_state__v": "VALID",' +
                            '"vid__v": "93358025901200' + currentEntityId + '",' +
                            '"entity_vid__v": "93358025901200' + currentEntityId + '",' +
                            '"postal_code__v": "91915",' +
                            '"administrative_area__v": "IL",' +
                            '"formatted_address__v": "200 Park Blvd. San Diego US-CA 91915",' +
                            '"address_ordinal__v": 1,' +
                            '"custom_keys__v": []' +
                        '}' +
                    '],' +
                    '"parent_hcos__v": [' +
                        '{' +
                            '"parent_hco_vid__v": "27112020000000001",' +
                            '"related_entity_type__v": "HCO",' +
                            '"record_owner_type__v": "VOD",' +
                            '"relationship_type__v": "3",' +
                            '"parent_type__v": "B",' +
                            '"status_update_time__v": "2020-11-27T00:00:00.000-08:00",' +
                            '"record_delta_id__v": "911272020000000001",' +
                            '"entity_type__v": "HCO",' +
                            '"hierarchy_type__v": "HCO_HCO",' +
                            '"record_owner_name__v": "OpenData",' +
                            '"modified_date__v": "2020-11-27T00:00:00.000-08:00",' +
                            '"parent_hco_corp_name__v": "Mavens Hospital",' +
                            '"record_state__v": "VALID",' +
                            '"parent_hco_status__v": "A",' +
                            '"is_primary_relationship__v": "N",' +
                            '"vid__v": "81127202000000001",' +
                            '"entity_vid__v": "27112020000000001",' +
                            '"created_date__v": "2020-11-28T00:00:00.000-08:00",' +
                            '"is_externally_mastered__v": false,' +
                            '"is_veeva_master__v": true' +
                        '},' +
                        '{' +
                            '"parent_hco_vid__v": "27112020000000002",' +
                            '"related_entity_type__v": "HCO",' +
                            '"record_owner_type__v": "VOD",' +
                            '"relationship_type__v": "3",' +
                            '"parent_type__v": "B",' +
                            '"status_update_time__v": "2020-11-27T00:00:00.000-08:00",' +
                            '"record_delta_id__v": "911272020000000002",' +
                            '"entity_type__v": "HCO",' +
                            '"hierarchy_type__v": "HCO_HCO",' +
                            '"record_owner_name__v": "OpenData",' +
                            '"modified_date__v": "2020-11-27T00:00:00.000-08:00",' +
                            '"parent_hco_corp_name__v": "Mavens Health Society",' +
                            '"record_state__v": "VALID",' +
                            '"parent_hco_status__v": "A",' +
                            '"is_primary_relationship__v": "N",' +
                            '"vid__v": "81127202000000002",' +
                            '"entity_vid__v": "27112020000000002",' +
                            '"created_date__v": "2020-11-28T00:00:00.000-08:00",' +
                            '"is_externally_mastered__v": false,' +
                            '"is_veeva_master__v": true' +
                        '}' +
                    ']' +
                '}' +
            '},';
        }

        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }

    private static String getHCOEntitiesForRetrieveSuccessResponseBody() {
        return '{' +
            '"entityId": "27112020000000001",' +
            '"entityType": "HCO",' +
            '"metaData": {},' +
            '"entity": {' +
                '"percent_medicaid__v": "A",' +
                '"hco_type__v": "4:4",' +
                '"record_owner_type__v": "VOD",' +
                '"lab_services__v": "N",' +
                '"npi_num__v": "11234567890",' +
                '"record_delta_id__v": "911272020000000002",' +
                '"record_owner_name__v": "OpenData",' +
                '"URL_2__v": "mavens.com",' +
                '"kaiser__v": "N",' +
                '"is_veeva_master__v": true,' +
                '"count_all_locn_md_do__v": 3448,' +
                '"status_update_time__v": "2020-11-27T00:00:00.000-08:00",' +
                '"URL_1__v": "www.mavens.com",' +
                '"modified_date__v": "2020-11-25T00:00:00.000-08:00",' +
                '"accept_medicaid__v": "Y",' +
                '"count_all_locn_non_md_do__v": 1787,' +
                '"record_version__v": 0,' +
                '"vid__v": "27112020000000001",' +
                '"is_externally_mastered__v": false,' +
                '"specialty_1__v": "CD",' +
                '"340B_eligible__v": "N",' +
                '"master_vid__v": "27112020000000001",' +
                '"hco_status__v": "A",' +
                '"accept_medicare__v": "Y",' +
                '"count_all_locn_medstaff__v": 5235,' +
                '"count_non_md_do__v": 2,' +
                '"primary_country__v": "US",' +
                '"top_parent__v": "732073044339692545",' +
                '"created_date__v": "2020-11-27T00:00:00.000-08:00",' +
                '"training_facility__v": "N",' +
                '"va_dod_affiliated__v": "N",' +
                '"major_class_of_trade__v": "45",' +
                '"count_medstaff__v": 8,' +
                '"count_md_do__v": 6,' +
                '"ama_do_not_contact__v": "N",' +
                '"percent_medicare__v": "A",' +
                '"corporate_name__v": "Mavens Hospital",' +
                '"ams_id__v": "2605538",' +
                '"record_state__v": "VALID",' +
                '"entity_is_third_party_master_for_search_only__v": false,' +
                '"xray_services__v": "N",' +
                '"roster_date__v": "2020-11-27",' +
            '}' +
        '}';
    }
}