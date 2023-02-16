/**
 * @author Mavens
 * @date May 2019
 * @description Controller for the DocuSign One Click lightning component
 * @group DocuSign One Click
 */
public with sharing class PJN_DocuSignOneClickCtrl {

    @TestVisible private static PJN_DocuSignOneClickMetadata metadataProvider = new PJN_DocuSignOneClickMetadata();

    /*
    *  @description Given an object Id, get a configuration setting, if available. If not then null
    *  @param - SObjectType - the SObject type to query
    *  @return PJN_DocuSign_One_Click_Setting__mdt
    */
    @AuraEnabled
    public static string generateEnvelopeParams(Id recordId){
        SObjectType objectType = recordId.getSobjectType();

        List<PJN_DocuSign_One_Click_Setting__mdt> settings = metadataProvider.getSettingsForObject(objectType);

        SObject record = queryRecord(recordId, settings);

        PJN_DocuSign_One_Click_Setting__mdt setting = filterSettings(record, settings);

        Map<String, String> urlParams = getUrlParams(setting, record);

        return formatUrlParameters(urlParams);
    }

    /*
    *  @description from the list of settings return all fields that need to be queried on the target record
    *  @param - Id - the recordId to query for
    *  @param - List<PJN_DocuSign_One_Click_Setting__mdt> - the settings used to figure out what fields to query
    *  @return SObject
    */
    private static SObject queryRecord(Id recordId, List<PJN_DocuSign_One_Click_Setting__mdt> settings) {
        List<String> queryFieldsList = new List<String>();
        queryFieldsList.addAll(getSetOfFieldsToQuery(settings));

        List<String> formatParams = new List<String> {
            String.join(queryFieldsList, ', '),
            recordId.getSobjectType().getDescribe().getName()
        };

        String queryString = 'SELECT {0} FROM {1} WHERE Id = :recordId';
        String formattedQueryString = String.format(queryString, formatParams);
        System.debug(formattedQueryString);

        List<SObject> sobjects = Database.query(formattedQueryString);

        if (sobjects.isEmpty()) {
            AuraHandledException auraEx = new AuraHandledException(Label.PJN_D1C_Unable_to_query_record);
            auraEx.setMessage(Label.PJN_D1C_Unable_to_query_record); // getMessage() returns 'Script-thrown Exception' without this.
            throw auraEx;
        }

        return sobjects[0];
    }

    /*
    *  @description given a list of DocuSign one click settings return a set of all fields to query for
    *  @param  - List<PJN_DocuSign_One_Click_Setting__mdt> the settings to evaluate
    *  @return - Set<String> - Set of field path strings to query for
    */
    private static Set<String> getSetOfFieldsToQuery(List<PJN_DocuSign_One_Click_Setting__mdt> settings) {
        Set<String> queryFields = new Set<String>{'Id'};
        for (PJN_DocuSign_One_Click_Setting__mdt setting : settings) {
            queryFields.add(setting.PJN_Program_Field__c);
            if (String.isNotBlank(setting.PJN_Additional_Filter_Field__c)) {
                queryFields.add(setting.PJN_Additional_Filter_Field__c);
            }

            if (String.isNotBlank(setting.PJN_Record_Type__c)) {
                queryFields.add('RecordType.DeveloperName');
            }

            // Query custom metadata in the for loop. There are no long text fields so this won't hit Query limits
            // doing it this way makes it much more testable
            for (PJN_DocuSign_One_Click_Recipient__mdt recipientConfig : metadataProvider.getRecipients(setting.Id)) {
                for (PJN_DocuSign_One_Click_Recipient_Field__mdt ocrf : metadataProvider.getRecipientFields(recipientConfig.Id)) {
                    if (String.isNotBlank(ocrf.PJN_Source_Field__c)) {
                         queryFields.add(ocrf.PJN_Source_Field__c);
                    }
                }
            }
        }
        return queryFields;
    }


    /*
    *  @description given an SObject and list of settings, return the first setting that matches or return an empty setting
    *  @param - SObject - the record to use for matching
    *  @param - List<PJN_DocuSign_One_Click_Setting__mdt> - the settings to filter
    *  @return PJN_DocuSign_One_Click_Setting__mdt
    */
    private static PJN_DocuSign_One_Click_Setting__mdt filterSettings(SObject record, List<PJN_DocuSign_One_Click_Setting__mdt> settings) {
        for (PJN_DocuSign_One_Click_Setting__mdt setting : settings) {
            // does this setting match the program for the record
            String programName = getStringValue(record, setting.PJN_Program_Field__c);
            String progDevName = setting.PJN_Program__r.DeveloperName;
            if (progDevName == null || programName != progDevName) {
                continue;
            }

            // is the Record type defined and if so does it match the record type of the record
            if (String.isNotBlank(setting.PJN_Record_Type__c)) {
                SObject recordType = record.getSObject('RecordType');
                String recordTypeDeveloperName = (String) recordType.get('DeveloperName');
                if (String.isBlank(recordTypeDeveloperName) || recordTypeDeveloperName != setting.PJN_Record_Type__c) {
                    continue;
                }
            }

            // is additional filter defined and if so does it match the defined filter value?
            if (String.isNotBlank(setting.PJN_Additional_Filter_Field__c)) {
                String additionalFilterField = (String) record.get(setting.PJN_Additional_Filter_Field__c);
                if (String.isBlank(additionalFilterField) || additionalFilterField != setting.PJN_Additional_Filter_Value__c) {
                    continue;
                }
            }

            // if code made it this far it's passed all checks and matches.
            return setting;
        }

        AuraHandledException auraEx = new AuraHandledException(Label.PJN_D1C_Unable_to_Locate_Setting);
        auraEx.setMessage(Label.PJN_D1C_Unable_to_Locate_Setting); // getMessage() returns 'Script-thrown Exception' without this.
        throw auraEx;
    }

    /*
    *  @description given an object and a string representing a path to a value, navigate the path to retrieve the value
    *  @param - SObject - the record to parse
    *  @param - String - represents path to the object
    *  @return String
    */
    private static String getStringValue(SObject record, String path) {
        List<String> fields = path.split('\\.');
        SObject currObj = record;
        while (fields.size() > 1) {
            currObj = currObj.getSObject(fields[0]);
            if(currObj == null) {
                return '';
            }
            fields.remove(0);
        }
        return (String) currObj.get(fields[0]);
    }

    /*
    *  @description given a setting and record, generate the url param key value pairs
    *  @param - PJN_DocuSign_One_Click_Setting__mdt - the configured one click setting to use
    *  @param - SObject - the SObject to source data from
    *  @return Map<String, String> a map of key value pairs for crating the url
    */
    private static Map<String, String> getUrlParams(PJN_DocuSign_One_Click_Setting__mdt setting, SObject record) {
        return new Map<String, String> {
            'SourceID' => (String) record.get('Id'),
            // TODO, implement way to set RC. possibly client side (GetRelContentIDs({!v.recordId});
            'RC' => setting.PJN_Related_Content__c ? ''  : '',
            'RSL' => stringFromNumber(setting.PJN_Recipient_Signer_Limit__c),
            'RSRO' => stringFromNumber(setting.PJN_Recipient_Starting_Routing_Order__c),
            'RROS' => setting.PJN_Recipient_Routing_Order_Sequential__c ? '1' : '0',
            'CCRM' => setting.PJN_Custom_Contact_Role_Map__c,
            'CCTM' => setting.PJN_Custom_Contact_Type_Map__c,
            'CCNM' => setting.PJN_Custom_Contact_Note_Map__c,
            'CRCL' => setting.PJN_Custom_Related_Contact_List__c,
            'CRL' => setting.PJN_Use_Custom_Recipients__c ? getCustomRecipients(setting, record) : '',
            'OCO' => setting.PJN_One_Click_Options__c,
            'DST' => getTemplateId(setting),
            'LA' => setting.PJN_Load_Attachments__c ? '1' : '0',
            'LF' => setting.PJN_Load_Files__c ? '1' : '0',
            'CEM' => setting.PJN_Custom_Email_Message__c,
            'CES' => setting.PJN_Custom_Email_Subject__c,
            'STB' => '', // not currently implemented
            'SSB' => '', // not currently implemented
            'SES' => '', // not currently implemented
            'SEM' => '', // not currently implemented
            'SRS' => '', // not currently implemented
            'SCS' => '', // not currently implemented
            'RES' => ''  // not currently implemented
        };
    }

    /*
    *  @description Given a decimal return a string value of the Integer representation
    *  @param - Decimal - the number to convert
    *  @return String
    */
    private static String stringFromNumber(Decimal num) {
        if (num == null) {
            return '';
        }
        return Integer.valueOf(num).format();
    }

    /*
    *  @description given a setting and record, generate all custom recipients
    *  @param - PJN_DocuSign_One_Click_Setting__mdt - the configured one click setting to use
    *  @param - SObject - the SObject to source data from
    *  @return  a String represting all custom recipients for docusign
    */
    private static String getCustomRecipients(PJN_DocuSign_One_Click_Setting__mdt setting, SObject record) {

        List<PJN_DocuSignRecipient> recipients = new List<PJN_DocuSignRecipient>();
        for (PJN_DocuSign_One_Click_Recipient__mdt recipientConfig : metadataProvider.getRecipients(setting.Id)) {
            PJN_DocuSignRecipient recipient = new PJN_DocuSignRecipient(recipientConfig.PJN_Type__c);
            for (PJN_DocuSign_One_Click_Recipient_Field__mdt ocrf : metadataProvider.getRecipientFields(recipientConfig.Id)) {
                String value = ocrf.PJN_Value__c;
                if (String.isNotBlank(ocrf.PJN_Source_Field__c)) {
                    value = getStringValue(record, ocrf.PJN_Source_Field__c);
                }
                recipient.fieldValuePairs.put(ocrf.PJN_Field__c, value);
            }
            recipients.add(recipient);
        }

        List<String> recipientStrings = new List<String>();
        for (PJN_DocuSignRecipient recipient : recipients) {
            try {
                recipientStrings.add(recipient.getFormattedString());
            } catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }

        String recipientString = String.join(recipientStrings, ',');
        if (String.isNotBlank(recipientString)) {
            recipientString += ',';
        }
        recipientString += 'LoadDefaultContacts~' + (setting.PJN_Load_Default_Contacts__c ? '1' : '0');
        return recipientString;
    }

    /*
    *  @description give a setting retrieve the template id corresponding to the template name
    *  @param - PJN_DocuSign_One_Click_Setting__mdt - the configured one click setting to use
    *  @return - the id on the configured custom setting that matches the template name
    */
    private static String getTemplateId(PJN_DocuSign_One_Click_Setting__mdt setting) {
        try {
            return [
                SELECT
                    PJN_Template_Id__c
                FROM
                    PJN_DocuSign_Template__c
                WHERE
                    PJN_Template_Name__c = :setting.PJN_Template_Name__c].PJN_Template_Id__c;
        } catch (System.QueryException ex) {
            String errorMessage = String.format(
                Label.PJN_D1C_Unable_to_Find_Template,
                new List<String>{ setting.PJN_Template_Name__c}
            );
            AuraHandledException auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage); // getMessage() returns 'Script-thrown Exception' without this.
            throw auraEx;
        }
    }

    /*
    *  @description given a Map of key/value string pairs return a formatted url params string
    *  @param - Map<String,String> - map of key/value string pairs
    *  @return - a formatted url params string
    */
    private static String formatUrlParameters(Map<String, String> urlParams) {
        List<String> formattedParamsList = new List<String>();
        for (String key : urlParams.keySet()) {
            formattedParamsList.add(
                key + '=' + (String.isNotBlank( (String) urlParams.get(key)) ? urlParams.get(key) : '')
            );
        }
        return String.join(formattedParamsList, '&');
    }
}