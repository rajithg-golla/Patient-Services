/**
 * @author      Mavens
 * @group       DataLake
 * @description Mock data for MVN_DataLakePayerMaster Test
 */
@IsTest
public with sharing class MVN_DataLakePayerMasterMock {
    public class SearchSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '';
            Map<String, Object> requestBody = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
            String query = String.valueOf(requestBody.get('query'));
            if(query.contains('data_precision_payer_spine_vw')) {
                responseBody = getPayerRetrieveSuccessResponseBody();
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

    private static String getPayerRetrieveSuccessResponseBody() {
        return '{' +
            '"Items": [' +
            getPayerEntitiesForRetrieveSuccessResponseBody() +
            ']' +
        '}';
    }

    private static String getPayerEntitiesForRetrieveSuccessResponseBody() {
        String entitiesForRetrieveSuccessResponseBody = '';
        for (Integer eIndex = 0; eIndex < 2000; eIndex++) {
            Integer currentEntityId = 6000 + eIndex;
            entitiesForRetrieveSuccessResponseBody += '{' +
                '"plan_id": "P0' + currentEntityId + '",' +
                '"plan": "Abbott EGWP",' +
                '"payerchannel_id": "B0' + currentEntityId + '",' +
                '"payerchannel": "Abbott - Medicare",' +
                '"payer_id": "E0' + currentEntityId + '",' +
                '"payer": "Abbott",' +
                '"medical_channel": "Medicare Advantage",' +
                '"pharmacy_channel": "Medicare Part D",' +
                '"channeldetail": "EGWP",' +
                '"pbm_id": "PBM0' + currentEntityId + '",' +
                '"medical_pbm_processor": "Express Scripts EGWP",' +
                '"pharmacy_pbm": "Express Scripts EGWP",' +
                '"pharmacy_pbm_relationship": "National",' +
                '"src_data_month": "2021-06-01",' +
                '"px_data_month": "2021-06-01",' +
                '"px_delivery_date": "2021-06-14"' +
            '},';
        }
        return entitiesForRetrieveSuccessResponseBody.substringBeforeLast(',');
    }
}