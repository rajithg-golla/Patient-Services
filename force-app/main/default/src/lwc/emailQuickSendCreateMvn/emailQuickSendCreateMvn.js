import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent"
import CASE_ACCOUNTID_FIELD from "@salesforce/schema/Case.AccountId";
import CASE_EMAIL_FIELD from "@salesforce/schema/Case.Account_Primary_Email_MVN__c";
import LEAD_EMAIL_FIELD from "@salesforce/schema/Lead.Email";
import CANCEL_BUTTON from "@salesforce/label/c.Email_Quick_Send_Cancel_Button_MVN";
import SEND_BUTTON from "@salesforce/label/c.Email_Quick_Send_Send_Button_MVN";
import SENT_MESAGE from "@salesforce/label/c.Email_Quick_Send_Success_Message_MVN";
import handleError from "c/pjnErrorHandler";

export default class EmailQuickSendCreateMvn extends LightningElement {
    @api objectId;

    email;
    leadId;
    caseId;
    accountId;
    currentEmailTemplate;

    disableSave = true;

    labels = {
        CANCEL_BUTTON,
        SEND_BUTTON
    };

    @wire(getRecord, { recordId: "$objectId", fields: LEAD_EMAIL_FIELD })
    handleResponse({error, data}) {
        this.handleGetRecordError(error);
        if (data && data.fields) {
            this.leadId = this.objectId;
            if (data.fields.Email) {
                this.email = data.fields.Email.value;
            }
        }
    }

    @wire(getRecord, { recordId: "$objectId", fields: [CASE_EMAIL_FIELD, CASE_ACCOUNTID_FIELD]})
    handleCaseResponse({error, data}) {
        this.handleGetRecordError(error);
        if (data && data.fields) {
            this.caseId = this.objectId;
            if (data.fields.Account_Primary_Email_MVN__c) {
                this.email = data.fields.Account_Primary_Email_MVN__c.value;
            }

            if (data.fields.AccountId) {
                this.accountId = data.fields.AccountId.value;
            }
        }
    }

    handleTemplateChange(event) {
        this.currentEmailTemplate = event.target.value;
        if (!this.currentEmailTemplate) {
            // no template selected
            this.disableSave = true;
        }
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Consumer_MVN__c = this.leadId;
        fields.Care_Plan_MVN__c = this.caseId;
        fields.Account_MVN__c = this.accountId;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleTemplateFound() {
        this.disableSave = false;
    }

    handleTemplateNotFound() {
        this.disableSave = true;
    }
    
    handleSuccess() {
        const event = new ShowToastEvent({
            message: SENT_MESAGE,
            variant: 'success'
        });
        this.dispatchEvent(event);

        this.closeQuickAction();
    }

    handleGetRecordError(error) {
        if (error && error.body && !error.body.errorCode === "INVALID_INPUT") {
            handleError(error);
        }
    }

    closeQuickAction() {
        this.dispatchEvent(
            new CustomEvent('closequickaction')
        );
    }
}