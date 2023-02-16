import { LightningElement, api, track, wire } from "lwc";
import { getRecordCreateDefaults } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fireEvent } from "c/pubsub";
import { CurrentPageReference } from "lightning/navigation";
import handleError from "c/pjnErrorHandler";
import RECORD_CREATED from "@salesforce/label/c.PJN_Medical_History_Record_Created";
import RECORD_CREATED_SUCCESSFULLY from "@salesforce/label/c.PJN_Medical_History_Record_Created_Successfully";
import CLOSE from "@salesforce/label/c.PJN_Medical_History_Close";
import CANCEL from "@salesforce/label/HealthCloudGA.Button_Label_Cancel";
import SAVE from "@salesforce/label/HealthCloudGA.Button_Label_Save";
import SAVE_NEW from "@salesforce/label/HealthCloudGA.Button_Label_Save_And_New";
import LOADING from "@salesforce/label/HealthCloudGA.Msg_Loading";

export default class PjnNewMedicalHistoryRecord extends LightningElement {
    @api patientId;
    @api carePlanId;
    @api recordTypeId;
    @api heading = "";
    @api showModal = false;

    @track newMedHistoryRecord;
    @track sections = [];
    @track saveButtonDisabled = false;

    labels = {
        CLOSE,
        CANCEL,
        LOADING,
        SAVE,
        SAVE_NEW
    };

    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecordCreateDefaults, { objectApiName: "PJN_Medical_History__c", recordTypeId: "$recordTypeId"})
    processRecord (response) {
        handleError(response.error);
        if (response.data) {
            this.newMedHistoryRecord = response.data.record;
            // get list of all filds on layout under layout > sections > layoutRows > layoutItems
            // return [{ id: "exampleId", fields: []}]
            this.sections = this.reduceToSectionsWithLayoutItems(response);
        }
    }

    // returns array of layout items pulled from a layout
    reduceToSectionsWithLayoutItems(response) {
        return response.data.layout.sections.reduce(
            (accumulator, section) => {
                const fields = this.reduceSection(section)
                    .filter( layoutItem => layoutItem.editableForNew)
                    .filter(
                        layoutItem =>
                            layoutItem.layoutComponents[0].apiName !== "PJN_Care_Plan__c" &&
                            layoutItem.layoutComponents[0].apiName !== "PJN_Patient__c"
                    )
                    .map( layoutItem => {
                        return {
                            apiName: layoutItem.layoutComponents[0].apiName,
                            label: layoutItem.label,
                            value: layoutItem.value,
                            required: layoutItem.required,
                            error: "",
                            errorClass: ""
                        };
                    });
                return [...accumulator, { id: section.id, fields } ];
            },
            []
        );
    }

    // returns array of layout items pulled from layout sections
    reduceSection(section) {
        return section.layoutRows.reduce( (rowAccum, layoutRow) => {
            return [...rowAccum, ...layoutRow.layoutItems];
        },[]);
    }

    handleSave(event){
        event.preventDefault();       // stop the form from submitting
        if (event.target.label === this.labels.CANCEL) {
            return;
        }
        this.saveButtonDisabled = true;
        const fields = event.detail.fields;
        fields.PJN_Care_Plan__c = this.carePlanId;
        fields.PJN_Patient__c = this.patientId;
        if(this.validate(fields)) {
            this.template.querySelector("lightning-record-edit-form").submit(fields);
        } else {
            this.andNew = false;
        }
        this.saveButtonDisabled = false;
    }

    setAndNew() {
        this.andNew = true;
    }

    validate(fields) {
        let valid = true;
        this.sections.forEach( section => {
            section.fields.forEach( field => {
                field.error = "";
                field.errorClass = "";
                if (field.required && !fields[field.apiName]) {
                    field.error = `${field.label} is required`;
                    field.errorClass = "slds-has-error";
                    valid = false;
                }
            });
        });
        return valid;
    }

    handleSuccess() {
        if (!this.andNew) {
            this.dispatchEvent(new CustomEvent("closemodal"));
        }
        this.andNew = false;
        const fields = this.template.querySelectorAll("lightning-input-field");
        if (fields) {
            fields.forEach( field => field.reset());
        }
        fireEvent(this.pageRef, "newrecordcreated");
        this.dispatchEvent(
            new ShowToastEvent({
                title: RECORD_CREATED,
                message: RECORD_CREATED_SUCCESSFULLY.replace("{0}", this.heading), // eg. New Vaccination record created successfully
                variant: "success"
            })
        );
    }

    handleFormError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: event.detail.message,
                message: event.detail.detail,
                variant: "error"
            })
        );
    }

    handleModalClose() {
        this.dispatchEvent(new CustomEvent("closemodal"));
    }
}