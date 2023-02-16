/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class AgreementTemplateService {
    global AgreementTemplateService() {

    }
    global static echosign_dev1.AgreementTemplateService.AgreementTemplateDetails getAgreementTemplateDetails(String templateId) {
        return null;
    }
    global static List<echosign_dev1.AgreementTemplateService.AgreementTemplateBasicInfo> getAgreementTemplateList(echosign_dev1.AgreementTemplateService.AgreementTemplateListOptions options) {
        return null;
    }
    global static String getAgreementTemplateUrl(String templateId) {
        return null;
    }
    global static String getNewAgreementTemplateUrl() {
        return null;
    }
    global static Id load() {
        return null;
    }
    global static Id load(String templateId) {
        return null;
    }
    global static Id load(String templateId, String masterId) {
        return null;
    }
    global static Id load(String templateId, String masterId, Map<String,echosign_dev1.AgreementTemplateVariable> agreementTemplateVariables) {
        return null;
    }
global class AgreementTemplateBasicInfo {
    global Integer daysUntilExpiration {
        get;
        set;
    }
    global Boolean isDefault {
        get;
        set;
    }
    global String language {
        get;
        set;
    }
    global String name {
        get;
        set;
    }
    global Id recordId {
        get;
        set;
    }
    global String url {
        get;
        set;
    }
    global AgreementTemplateBasicInfo() {

    }
}
global class AgreementTemplateDetails {
    global List<String> ccList {
        get;
        set;
    }
    global String dataMappingName {
        get;
        set;
    }
    global String mergeMappingName {
        get;
        set;
    }
    global String message {
        get;
        set;
    }
    global List<echosign_dev1.AgreementTemplateService.RecipientInfo> recipients {
        get;
        set;
    }
    global String url {
        get;
        set;
    }
    global AgreementTemplateDetails() {

    }
}
global class AgreementTemplateListOptions {
    global Boolean autoSend {
        get;
        set;
    }
    global Boolean hasAttachment {
        get;
        set;
    }
    global Boolean hasRecipient {
        get;
        set;
    }
    global Boolean isActive {
        get;
        set;
    }
    global String masterObjectType {
        get;
        set;
    }
    global AgreementTemplateListOptions() {

    }
    global AgreementTemplateListOptions(String masterObjectType, Boolean isActive, Boolean hasAttachment, Boolean hasRecipient, Boolean autoSend) {

    }
}
global class RecipientInfo {
    global String recipientName {
        get;
        set;
    }
    global String recipientRole {
        get;
        set;
    }
    global String recipientType {
        get;
        set;
    }
    global Decimal signOrder {
        get;
        set;
    }
    global RecipientInfo() {

    }
}
}
