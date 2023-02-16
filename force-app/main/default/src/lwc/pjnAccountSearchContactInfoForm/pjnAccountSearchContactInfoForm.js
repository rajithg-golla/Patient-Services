import { LightningElement, api, track } from "lwc";
import MODAL_TITLE_LABEL from "@salesforce/label/c.PJN_New_Account_Add_Contact_Info_Title";

export default class PjnAccountSearchContactInfoForm extends LightningElement {
    @api contactInfoRecordTypeId;
    @api ciRecTypeOptionsMap;
    @api fieldsetMapContactInfo;
    @api fieldsetContactInfo;
    @api defaultCountry;
    @api contactInfoList;
    @api searchContactInfoValues;
    @api index;
    @api inModal = false;

    @track newContactInfo;

    @track labels = {
        MODAL_TITLE: MODAL_TITLE_LABEL.replace("{0}", "Add"),
        SUBMIT_LABEL: "Add",
        NEW_HEADER: "New Contact Info Record"
    };

    connectedCallback() {
        // if we have a contact info list and the index is in that range load up that record for edit
        if (this.contactInfoList && this.index < this.contactInfoList.length) {
            this.labels.SUBMIT_LABEL = "Update";
            this.labels.MODAL_TITLE = MODAL_TITLE_LABEL.replace("{0}", "Update");
            this.newContactInfo = this.contactInfoList[this.index];
            this.contactInfoRecordTypeId = this.newContactInfo.RecordTypeId;
        } else {
            this.SUBMIT_LABEL = "Add";
            this.labels.MODAL_TITLE = MODAL_TITLE_LABEL.replace("{0}", "Add");
            this.newContactInfo = { PJN_Country__c : this.defaultCountry };

            // if a contact info record of this type already exists don't default primary to true
            if (this.contactInfoList && this.contactInfoList.find( ci => ci.RecordTypeId === this.contactInfoRecordTypeId)) {
                this.newContactInfo.PJN_Set_as_Primary__c = false;
            }
        }

        if (this.ciRecTypeOptionsMap) {
            const recTypeOption = this.ciRecTypeOptionsMap[this.contactInfoRecordTypeId];
            this.labels.NEW_HEADER = `New ${recTypeOption.label} Record`;
            const recTypeDeveloperName = recTypeOption != null ? recTypeOption.developerName : "";
            this.fieldsetContactInfo = this.fieldsetMapContactInfo[recTypeDeveloperName];
        }

        if (!(this.contactInfoList && this.index < this.contactInfoList.length) && this.searchContactInfoValues) {
            this.fieldsetContactInfo.forEach(fieldSetCIItem => {
                if (this.searchContactInfoValues[fieldSetCIItem.PJN_Field_API_Name__c]) {
                    this.newContactInfo[fieldSetCIItem.PJN_Field_API_Name__c] = this.searchContactInfoValues[fieldSetCIItem.PJN_Field_API_Name__c];
                }
            });
        }
    }

    handleFormLoad() {
        // default the values when the record edit form loads
        this.template.querySelectorAll("lightning-input-field").forEach( field => {
            field.value = this.newContactInfo[field.fieldName];
        });
    }

    handleSubmit(event) {
        if (this.index !== null) {
            event.preventDefault();
            const submittedRecordEvent =  new CustomEvent("submittedrecord", {
                detail: {
                    index: this.index,
                    fields: event.detail.fields
                }
            });
            if (submittedRecordEvent.detail.fields) {
                submittedRecordEvent.detail.fields.RecordTypeId = this.contactInfoRecordTypeId;
                this.dispatchEvent( submittedRecordEvent );
            }
        }

    }

    clearRecTypeId() {
        this.contactInfoRecordTypeId = null;
    }

    cancel() {
        const closeModal =  new CustomEvent("closemodal", {
            detail: {
                index: this.contactInfoList.length
            }
        });

        this.dispatchEvent( closeModal );
    }
}