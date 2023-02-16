import { LightningElement, api, wire, track } from "lwc";
import { createRecord } from "lightning/uiRecordApi";
import handleError from "c/pjnErrorHandler";
import getMetricRecTypeId from "@salesforce/apex/PJN_MedicalHistoryCtrl.getMetricRecTypeId";
import getMetricTypeWithOptions from "@salesforce/apex/PJN_MetricsCtrl.getMetricTypeWithOptions";
import MEDICAL_HISTORY_OBJECT from "@salesforce/schema/PJN_Medical_History__c";
import PICKLIST_SELECT_LABEL from "@salesforce/label/c.PJN_Medical_History_Picklist_Select";
import PROVIDE_DATE_LABEL from "@salesforce/label/c.PJN_Medical_History_Provide_Date";
import PROVIDE_VALUE_LABEL from "@salesforce/label/c.PJN_Medical_History_Provide_Value";
import SAVE_LABEL from "@salesforce/label/HealthCloudGA.Button_Label_Save";

export default class PjnCaptureMetric extends LightningElement {
    @api carePlanId;
    @api patientId;
    @api metricTypeId;

    @track saveButtonDisabled = false;
    @track metricType = {};
    @track pickListOptions;
    @track newMetricDate = new Date().toISOString();

    saveLabel = SAVE_LABEL;

    _metricRecTypeId;

    /*
     *given a metric type id, call apex to query for metric type and any child option recrords
     */
    @wire(getMetricTypeWithOptions, {metricTypeId: "$metricTypeId"}) processMetric(response) {
        handleError(response.error);
        if (response.data) {
            this.metricType = response.data;
            if (response.data.PJN_Metric_Type_Options__r) {
                this.pickListOptions = response.data.PJN_Metric_Type_Options__r.map( option => {
                    return {
                        label: option.Name,
                        value: option.PJN_Value__c ? option.PJN_Value__c : option.Name
                    };
                });
                this.pickListOptions.unshift({label: PICKLIST_SELECT_LABEL, value: ""});
            }
        }
    }

    /* for an inexplicible reason salesforce does not return record type ids with "getObjectInfo" call */
    @wire(getMetricRecTypeId) setMetricRecTypeId(response) {
        handleError(response.error);
        if (response.data) {
            this._metricRecTypeId = response.data;
        }
    }

    get type() {
        return this.metricType.PJN_Type__c;
    }

    get isNumber() {
        return this.type === "Number";
    }

    get isPicklist() {
        return this.type === "Picklist";
    }

    newMetricDateHandler(event) {
        this.newMetricDate = event.target.value;
    }

    save() {
        this.saveButtonDisabled = true;
        let input;
        if (this.isNumber) {
            input = this.template.querySelector("input");
        }
        if (this.isPicklist) {
            input = this.template.querySelector("select.slds-select");
        }

        if (!input.value) {
            handleError(PROVIDE_VALUE_LABEL)
                .then(() => {
                    this.saveButtonDisabled = false;
                });
            return;
        }

        if (!this.newMetricDate) {
            handleError(PROVIDE_DATE_LABEL)
                .then(() => {
                    this.saveButtonDisabled = false;
                });
            return;
        }

        createRecord({
            apiName: MEDICAL_HISTORY_OBJECT.objectApiName,
            fields: {
                RecordTypeId: this._metricRecTypeId,
                PJN_Care_Plan__c: this.carePlanId,
                PJN_Metric_Type__c: this.metricTypeId,
                PJN_Patient__c: this.patientId,
                PJN_Date__c: this.newMetricDate,
                PJN_Value__c: input.value
            }
        })
            .then( () => {
                this.dispatchEvent(new CustomEvent("newmetric", { bubbles: true }));
                input.value = "";
            })
            .catch( error => handleError(error))
            .finally(() => {
                this.saveButtonDisabled = false;
            });

    }
}