/**
 * @author      Mavens
 * @group       AdobeSign
 * @description Controller for the Lead Consent quick action
 *     - Handles creation of agreement object and api wrapper plus callout to Adobe to send and inserting new record
 *     - Handles obtaining signing url for an agreement
 */
public with sharing class LeadConsentCtrlMVN {
    
    /**
     * Create an agreement and send it out for signature. insert agreeement record into Database and attach to lead
     * @param leadId - Id
     * @param templateName - String
     * @param signInPerson - Boolean
     * @return String
     */
    @AuraEnabled
    public static String createAndSendAgreement(Id leadId, String templateName, Boolean signInPerson) {
        // Get Template
        echosign_dev1__Agreement_Template__c template = [
            SELECT 
                Id,
                echosign_dev1__Agreement_Type__c,
                echosign_dev1__Name__c,                
                echosign_dev1__Data_Mapping__c,
                echosign_dev1__Merge_Mapping__c,
                echosign_dev1__Post_Sign_Redirect_Delay__c,
                echosign_dev1__Post_Sign_Redirect_URL__c,
                (
                    SELECT
                        Id,
                        echosign_dev1__Attachment_Document__c,
                        echosign_dev1__Type__c
                    FROM 
                        echosign_dev1__Attachment_Templates__r
                )
            FROM echosign_dev1__Agreement_Template__c
            WHERE Name = :templateName
            LIMIT 1
        ];

        Set<String> leadFields = new Set<String>{ 'Id', 'Email' };
        Map<String, String> formFieldToLeadField = new Map<String, String>();

        // get lead and designated fields from the template merge Mapping
        if (template.echosign_dev1__Merge_Mapping__c != null) {
            List<echosign_dev1__SIGN_Form_Field_Mapping__c> formFieldMappings = [
                SELECT
                    Id,
                    echosign_dev1__Form_Field_Name__c,
                    (
                        SELECT echosign_dev1__Field_Reference_Name__c
                        FROM echosign_dev1__Object_Field_Mappings__r
                        WHERE echosign_dev1__Object_Reference_Path__c = 'echosign_dev1__Recipient_Lead__r'
                        AND echosign_dev1__Type__c = 'Salesforce Object Field'
                    )
                FROM
                    echosign_dev1__SIGN_Form_Field_Mapping__c
                WHERE 
                    echosign_dev1__Data_Mapping__c = :template.echosign_dev1__Merge_Mapping__c
            ];
            
            for (echosign_dev1__SIGN_Form_Field_Mapping__c formFieldMapping : formFieldMappings) {
                for (echosign_dev1__SIGN_Form_Field_Mapping_Entry__c entry : formFieldMapping.echosign_dev1__Object_Field_Mappings__r) {
                    leadFields.add(entry.echosign_dev1__Field_Reference_Name__c);
                    if (!formFieldToLeadField.containsKey(formFieldMapping.echosign_dev1__Form_Field_Name__c)) {
                        // for DEDSI Leads assumptoin is there is only one mapping and take the first one from the children
                        formFieldToLeadField.put(
                            formFieldMapping.echosign_dev1__Form_Field_Name__c, 
                            entry.echosign_dev1__Field_Reference_Name__c
                        );
                    }
                }
            }
        }

        // query for the consumer
        Lead consumer = Database.query(
            'SELECT ' +
            String.join(new List<String>(leadFields), ', ') + ' ' +
            'FROM Lead ' +
            'WHERE Id = :leadId'
        );

        // create agreement API wrapper and populate
        String signatureType = 'ESIGN';
        String state = 'IN_PROCESS';
        String externalId = leadId;

        AdobeSignAgreementMVN agreement = new AdobeSignAgreementMVN(template.echosign_dev1__Name__c, signatureType, state, externalId)
            .addSigners(new List<String> {consumer.Email})
            .addEmailOption('ALL', 'ALL', signInPerson ? 'NONE' : 'ALL');
        
        if (!signInPerson) {
            agreement.addPostSignOption(
                template.echosign_dev1__Post_Sign_Redirect_URL__c, 
                template.echosign_dev1__Post_Sign_Redirect_Delay__c
            );
        }
        
        for (echosign_dev1__Attachment_Template__c document : template.echosign_dev1__Attachment_Templates__r) {
            if (document.echosign_dev1__Type__c == 'Document from EchoSign Library') {
                agreement.addLibraryFileInfo(document.echosign_dev1__Attachment_Document__c);
            }
        }

        for (String formField : formFieldToLeadField.keySet()) {
            String leadField = formFieldToLeadField.get(formField);
            Object fieldValue = consumer.get(leadField);
            DisplayType dt = Lead.sObjectType.getDescribe().fields.getMap().get(leadField).getDescribe().getType();
            String stringValue;
            if (dt == DisplayType.DATE && consumer.get(leadField) != null ) {
                Date dateValue = (Date) consumer.get(leadField);
                stringValue = dateValue.month() + '/' + dateValue.day() + '/' + dateValue.year();
            } else {
               stringValue = (String) consumer.get(leadField); 
            }
            agreement.addMergeField(formField, stringValue);
        }

        String agreementId = AdobeSignAPIMVN.sendForSigning(agreement);
        
        // create the new agreement object
        echosign_dev1__SIGN_Agreement__c agreementObject = new echosign_dev1__SIGN_Agreement__c(
            Name = template.echosign_dev1__Name__c,
            echosign_dev1__Recipient_Lead__c = leadId,
            echosign_dev1__Process_Template__c = template.echosign_dev1__Data_Mapping__c,
            echosign_dev1__Merge_Mapping__c = template.echosign_dev1__Merge_Mapping__c,
            echosign_dev1__Agreement_Type__c = template.echosign_dev1__Agreement_Type__c,
            CustomConsumer__c = leadId,
            echosign_dev1__Document_Key__c = agreementId,
            echosign_dev1__Post_Sign_Redirect_URL__c = template.echosign_dev1__Post_Sign_Redirect_URL__c,
            echosign_dev1__Post_Sign_Redirect_Delay__c = template.echosign_dev1__Post_Sign_Redirect_Delay__c,
            echosign_dev1__Recipient_Addresses__c = consumer.Email,
            echosign_dev1__SignatureOrder__c = 'Recipient signs, then I sign',
            echosign_dev1__SignatureType__c = 'e-Signature',
            echosign_dev1__Status__c = 'Out for Signature',
            echosign_dev1__Enable_Hosted_Signing__c = signInPerson
        );

        insert agreementObject;

        return agreementId;
    }

    /**
     * Retrieves signing urls and returns the first one.
     * @param agreementId - String
     * @return String
     */
    @AuraEnabled
    public static string getSigningUrl(String agreementId) {
        AdobeSignAPIMVN.SigningUrlResponse signingUrlResp = AdobeSignAPIMVN.getSigningUrl(agreementId);
        System.debug(JSON.serialize(signingUrlResp));
        if (!signingUrlResp.signingUrlSetInfos.isEmpty() && !signingUrlResp.signingUrlSetInfos[0].signingUrls.isEmpty()) {
            return signingUrlResp.signingUrlSetInfos[0].signingUrls[0].esignUrl;
        }
        return null;
    }

    @AuraEnabled
    public static string getAgreementDocId(Id agreementId) {
        return [
            SELECT echosign_dev1__Document_Key__c
            FROM echosign_dev1__SIGN_Agreement__c
            WHERE Id = :agreementId
        ].echosign_dev1__Document_Key__c;
    }
}