/**
 * @author      Mavens
 * @date        April 2019
 * @description Used by quick action on the fulfillment request record to submit record
 * @group       Fulfillment
 */
public with sharing class PJN_SubmitFulfillmentRequestCtrl {

    private static final Map<String, String> FULFILLMENT_RECORD_TYPE_MAPPING = new Map<String, String> {
        'PJN_SP_Triage' => 'MVN_SP_Triage_Submitted',
        'MVN_Copay_Claim' => 'MVN_Copay_Claim_Submitted',
        'PJN_Materials_Order' => 'PJN_Materials_Order'
    };
    private static final Set<String> FULFILLMENT_REQUEST_STD_FIELDS = new Set<String> {
        'PJN_Fulfillment_Request_Status__c',
        'PJN_Date_Submitted__c',
        'RecordTypeId',
        'RecordType.DeveloperName'
    };
    private static final Map<String, Schema.SObjectField> FULFILLMENT_FIELDS = Schema.SObjectType.PJN_Fulfillment_Request__c.fields.getMap();
    private static final Set<String> SP_TRIAGE_REQUIRED_FIELDS = new Set<String> {
        'MVN_Patient_Id__c',
        'PJN_Patient_Last_Name__c',
        'PJN_Patient_First_Name__c',
        'PJN_Patient_DOB__c',
        'PJN_Patient_Gender__c',
        'PJN_Patient_Address_Line_1__c',
        'PJN_Patient_City__c',
        'PJN_Patient_State__c',
        'PJN_Patient_Postal_Code__c',
        'PJN_Patient_Phone__c',
        'MVN_ICD_10_CM_Diagnosis_Code__c',
        'PJN_Physician_Last_Name__c',
        'PJN_Physician_First_Name__c',
        'PJN_Physician_Address_Line_1__c',
        'PJN_Physician_City__c',
        'PJN_Physician_State__c',
        'PJN_Physician_Postal_Code__c',
        'PJN_Physician_NPI__c',
        'PJN_Date_of_Rx__c',
        'PJN_NDC__c',
        'PJN_Care_Plan__c',
        'MVN_Patient_Diagnosis__c',
        'MVN_Clinical_Trial_Transition_Patient__c'
    };
    private static Set<String> visitedFields = new Set<String>();

    @AuraEnabled
    public static Boolean submitFulfillmentRecord(Id recordId){
        PJN_Fulfillment_Request__c fulfillment = getFulfillmentRequest(recordId);
        if (fulfillment.PJN_Fulfillment_Request_Status__c == 'Submitted') {
            return false;
        }
        Set<String> noFilledRequiredFields = getNoFilledRequiredFields(fulfillment);
        if (!noFilledRequiredFields.isEmpty()) {
            String fields = '';
            System.debug('### Missing required fields:');
            for (String noFilledRequiredField : noFilledRequiredFields) {
                System.debug('' + noFilledRequiredField);
                fields += noFilledRequiredField + ', ';
            }
            String errorMessage = String.format(Label.MVN_Missing_Required_Fields_Submitting_Fulfillment_Error_Message, new List<String>{fields.substringBeforeLast(', ')});
            AuraHandledException auraException = new AuraHandledException(errorMessage);
            auraException.setMessage(errorMessage);
            throw auraException;
        }
        if (!fulfillment.RecordType.DeveloperName.equals('PJN_Materials_Order') && !getIfFilesAttached(fulfillment)) {
            AuraHandledException auraException = new AuraHandledException(Label.MVN_Missing_Files_Submitting_Fulfillment_Error_Message);
            auraException.setMessage(Label.MVN_Missing_Files_Submitting_Fulfillment_Error_Message);
            throw auraException;
        }
        fulfillment.PJN_Fulfillment_Request_Status__c = 'Submitted';
        fulfillment.PJN_Date_Submitted__c = Datetime.now();
        fulfillment.RecordTypeId = getNewFulfillmentRecordType(fulfillment);
        try {
            update fulfillment;
            return true;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }
    }

    private static PJN_Fulfillment_Request__c getFulfillmentRequest(Id recordId) {
        String fields = getFulfillmentRequestFields(FULFILLMENT_REQUEST_STD_FIELDS);
        fields += getFulfillmentRequestFields(SP_TRIAGE_REQUIRED_FIELDS);
        String query = 'SELECT ' + fields.substringBeforeLast(',') + ' FROM PJN_Fulfillment_Request__c WHERE Id = :recordId';
        return (PJN_Fulfillment_Request__c) Database.query(query);
    }

    private static String getFulfillmentRequestFields(Set<String> frFields) {
        String fields = '';
        for (String frField : frFields) {
            if (!visitedFields.contains(frField)) {
                fields += frField + ',';
                visitedFields.add(frField);
            }
        }
        return fields;
    }

    private static Boolean getIfFilesAttached(PJN_Fulfillment_Request__c fulfillment) {
        List<ContentDocumentLink> cdls = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :fulfillment.Id
            LIMIT 1
        ];
        return !cdls.isEmpty();
    }

    private static Set<String> getNoFilledRequiredFields(PJN_Fulfillment_Request__c fulfillmentRequest) {
        Set<String> noFilledRequiredFields = new Set<String>();
        if (fulfillmentRequest.RecordType.DeveloperName == 'PJN_SP_Triage') {
            noFilledRequiredFields.addAll(getNoFilledRequiredSPTriage(fulfillmentRequest));
        }
        return noFilledRequiredFields;
    }

    private static Set<String> getNoFilledRequiredSPTriage(PJN_Fulfillment_Request__c fulfillmentRequest) {
        Set<String> noFilledRequiredFields = new Set<String>();
        for (String spTriageField : SP_TRIAGE_REQUIRED_FIELDS) {
            if (!FULFILLMENT_FIELDS.containsKey(spTriageField)) {
                continue;
            }
            Boolean noFilled = fulfillmentRequest.get(spTriageField) == null || String.isBlank(String.valueOf(fulfillmentRequest.get(spTriageField)));
            if (noFilled) {
                noFilledRequiredFields.add(FULFILLMENT_FIELDS.get(spTriageField).getDescribe().getLabel());
            }
        }
        return noFilledRequiredFields;
    }

    private static Id getNewFulfillmentRecordType(PJN_Fulfillment_Request__c fulfillmentRequest) {
        if (!FULFILLMENT_RECORD_TYPE_MAPPING.containsKey(fulfillmentRequest.RecordType.DeveloperName)) {
            return fulfillmentRequest.RecordTypeId;
        }
        String newRecordTypeDevName = FULFILLMENT_RECORD_TYPE_MAPPING.get(fulfillmentRequest.RecordType.DeveloperName);
        return Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName().containsKey(newRecordTypeDevName) ?
            Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName().get(newRecordTypeDevName).getRecordTypeId() :
            fulfillmentRequest.RecordTypeId;
    }
}