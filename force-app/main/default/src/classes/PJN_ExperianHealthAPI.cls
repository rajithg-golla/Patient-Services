/**
 * @author      Mavens
 * @date        10/2020
 * @description Wrapper for the Experian Health API (PFC for Pharmacy Hubs v1.4)
 * @group       ExperianHealthAPI
 */
public with sharing class PJN_ExperianHealthAPI implements PJN_FinancialClearingHouseIntf {

    public PJN_PAPEligibilityResponse getEligibility(PJN_PAPEligibilityRequest request) {
        PJN_ExperianHealthApiInquiry inquiry = new PJN_ExperianHealthApiInquiry(request);

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndPoint('callout:PJN_Experian_Health_API/rest/jersey/search/run');
        httpReq.setMethod('PUT');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setTimeout(60000);
        httpReq.setBody(
            JSON.serialize(
                new Map<String,Object> {
                    'detail' => new Map<String, Object> {
                        'type' => 'API Financial Assistance Screening',
                        'inquiry' => inquiry,
                        'username' => '<username>' // TODO: experian credentials
                    }
                }
            )
        );

        System.debug(LoggingLevel.DEBUG, 'httpReq::' + httpReq.toString());
        System.debug(LoggingLevel.DEBUG, 'httpReq:body::' + httpReq.getBody());

        HttpResponse response = new Http().send(httpReq);

        System.debug(LoggingLevel.DEBUG, 'response::' + response.getBody());

        Map<String, Object> responseDetail = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        PJN_PAPEligibilityResponse eligibilityResponse = new PJN_PAPEligibilityResponse();

        if (response.getStatusCode() == 200) {
            Map<String, Object> detail = (Map<String, Object>) responseDetail.get('detail');
            List<Object> responseResults = (List<Object>) detail.get('result');

            // only looking at the first result for now
            PJN_ExperianHealthApiResult experianApiResult = new PJN_ExperianHealthApiResult(
                (Map<String, Object>) responseResults[0]
            );

            eligibilityResponse
                .setEstimatedHouseholdSize(experianApiResult.householdSizeEstimate)
                .setEstimatedHouseholdIncome(experianApiResult.householdIncomeEstimate)
                .setFederalPovertyLevelPercent(experianApiResult.fplPercentage);
        } else {
            List<Object> errors = (List<Object>) responseDetail.get('errors');
            if (!errors.isEmpty()) {
                for (Object errorObject : errors) {
                    Object message =  ((Map<String, Object>) errorObject).get('exceptionMessage');
                    Object messageId =  ((Map<String, Object>) errorObject).get('messageId');
                    if (message != null) {
                        eligibilityResponse.addError((String) message + ' (Message Id: ' + (String) messageId + ')');
                    }
                }
            }
        }

        return eligibilityResponse;
    }
}