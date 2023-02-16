/**
 * @author      Mavens
 * @description Exposes /submit for POST calls. Class process JSON and returns a very basic response.
 */
@RestResource(urlMapping='/submit')
@SuppressWarnings('PMD.ApexCRUDViolation')
global without sharing class LibtayoMarketingAPIMVN {

    @HttpPost
    global static void handlePost() {
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            // pending lead insertion 
            Pending_Lead_MVN__c pendingLead = buildPendingLead(bodyMap);
            pendingLead.JSON_Received_MVN__c = req.requestBody.toString();
            insert pendingLead;

            if (String.isNotBlank(pendingLead.Agreement_Id_MVN__c)) {
                echosign_dev1__SIGN_Agreement__c agreement = buildAgreement(pendingLead);

                insert agreement;
            }

            RestResponse res = buildResponse(200, 'SUCCESS');
        } catch (Exception e) {
            RestResponse res = buildResponse(400, 'ERROR', 'Salesforce Error: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    private static Pending_Lead_MVN__c buildPendingLead(Map<String, Object> bodyMap) {
        List<Pending_Lead_Mapping_MVN__mdt> leadMappings = [SELECT JSON_Field_MVN__c, Pending_Consumer_Field_MVN__c FROM Pending_Lead_Mapping_MVN__mdt WHERE Active_MVN__c = true];

        Pending_Lead_MVN__c pendingLead = new Pending_Lead_MVN__c();

        for (Pending_Lead_Mapping_MVN__mdt leadMapping : leadMappings) {

            // if statement to check if custom metadata record is valid
            if (Schema.getGlobalDescribe().get('Pending_Lead_MVN__c').getDescribe().fields.getMap().containsKey(leadMapping.Pending_Consumer_Field_MVN__c)) {
                Schema.DisplayType displayType = Schema.getGlobalDescribe().get('Pending_Lead_MVN__c').getDescribe().fields.getMap().get(leadMapping.Pending_Consumer_Field_MVN__c).getDescribe().getType(); 
                String fieldName = leadMapping.Pending_Consumer_Field_MVN__c;

                if (bodyMap.containsKey(leadMapping.JSON_Field_MVN__c) && String.isNotBlank((String) bodyMap.get(leadMapping.JSON_Field_MVN__c))) {
                    switch on (String) displayType.name() {
                        when 'BOOLEAN' {
                            pendingLead.put(fieldName, Boolean.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'ADDRESS' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'COMBOBOX' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'CURRENCY' {
                            pendingLead.put(fieldName, bodyMap.get(leadMapping.JSON_Field_MVN__c));
                        }
                        when 'DATE' {
                            pendingLead.put(fieldName, Date.parse((String) bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        }
                        when 'DATETIME' {
                            pendingLead.put(fieldName, DateTime.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        }
                        when 'DATACATEGORYGROUPREFERENCE' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'EMAIL' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'ENCRYPTEDSTRING' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'LONG' {
                            pendingLead.put(fieldName, bodyMap.get(leadMapping.JSON_Field_MVN__c));
                        }
                        when 'PHONE' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'PICKLIST' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'REFERENCE' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'STRING' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'TEXTAREA' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        } 
                        when 'URL' {
                            pendingLead.put(fieldName, String.valueOf(bodyMap.get(leadMapping.JSON_Field_MVN__c)));
                        }
                    }
                }
            }
        }

        pendingLead.Agreement_Status_MVN__c = 'Out for Signature';

        return pendingLead;
    }

    private static echosign_dev1__SIGN_Agreement__c buildAgreement(Pending_Lead_MVN__c pendingLead) {
        // Get Template
        echosign_dev1__Agreement_Template__c template = [
            SELECT 
                echosign_dev1__Agreement_Type__c,
                echosign_dev1__Name__c,                
                echosign_dev1__Data_Mapping__c,
                echosign_dev1__Merge_Mapping__c,
                echosign_dev1__Post_Sign_Redirect_Delay__c,
                echosign_dev1__Post_Sign_Redirect_URL__c,
                (
                    SELECT
                        echosign_dev1__Attachment_Document__c,
                        echosign_dev1__Type__c
                    FROM 
                        echosign_dev1__Attachment_Templates__r
                )
            FROM echosign_dev1__Agreement_Template__c
            WHERE Name = 'Libtayo Consent'
            LIMIT 1
        ];

        // create the new agreement object
        return new echosign_dev1__SIGN_Agreement__c(
            Name = template.echosign_dev1__Name__c,
            // echosign_dev1__Recipient_Lead__c = pendingLead.Id,
            echosign_dev1__Process_Template__c = template.echosign_dev1__Data_Mapping__c,
            echosign_dev1__Merge_Mapping__c = template.echosign_dev1__Merge_Mapping__c,
            echosign_dev1__Agreement_Type__c = template.echosign_dev1__Agreement_Type__c,
            Pending_Lead_MVN__c = pendingLead.Id,
            echosign_dev1__Document_Key__c = pendingLead.Agreement_Id_MVN__c,
            echosign_dev1__Post_Sign_Redirect_URL__c = template.echosign_dev1__Post_Sign_Redirect_URL__c,
            echosign_dev1__Post_Sign_Redirect_Delay__c = template.echosign_dev1__Post_Sign_Redirect_Delay__c,
            echosign_dev1__Recipient_Addresses__c = pendingLead.Email_MVN__c,
            echosign_dev1__SignatureOrder__c = 'Recipient signs',
            echosign_dev1__SignatureType__c = 'e-Signature',
            echosign_dev1__Status__c = 'Out of Signature',
            echosign_dev1__Enable_Hosted_Signing__c = false
        );
    }

    private static RestResponse buildResponse(Integer statusCode, String responseStatus) {
        return buildResponse(statusCode, responseStatus, '');
    }

    private static RestResponse buildResponse(Integer statusCode, String responseStatus, String message) {
        RestResponse result = RestContext.response;
        result.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(responseStatus, message)));
        result.statusCode = statusCode;
        System.debug('#### result.responseBody: ' + result.responseBody);
        System.debug('#### result.statusCode: ' + result.statusCode);
        System.debug('#### result: ' + result);
        return result;
    }

    private class ResponseWrapper {
        String status = '';
        String message = '';

        public ResponseWrapper(String responseStatus, String message) {
            this.status = responseStatus;
            this.message = message;
        }
    }
}