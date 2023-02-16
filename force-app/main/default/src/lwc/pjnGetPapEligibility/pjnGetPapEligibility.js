import { LightningElement, api, wire } from "lwc";
import getPapEligibility from "@salesforce/apex/PJN_EvaluatePAPEligibilityCtrl.getPapEligibility";
import getPayloadRecord from "@salesforce/apex/PJN_EvaluatePAPEligibilityCtrl.getPayloadRecord";

import handleError from "c/pjnErrorHandler";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ASSISTANCE_PROG_ELIG_OBJECT from '@salesforce/schema/PJN_Assistance_Program__c';

// import labels
import CANCEL from "@salesforce/label/c.PJN_Eval_PAP_Cancel";
import ERROR from "@salesforce/label/c.PJN_Eval_PAP_Error";
import FINISH from "@salesforce/label/c.PJN_Eval_PAP_Finish";
import FIELD from "@salesforce/label/c.PJN_Eval_PAP_Field";
import MODAL_HEADER from "@salesforce/label/c.PJN_Eval_PAP_Modal_Header";
import OUTCOME_LABEL from "@salesforce/label/c.PJN_Eval_PAP_Outcome";
import RESULT from "@salesforce/label/c.PJN_Eval_PAP_Result";
import SOURCE from "@salesforce/label/c.PJN_Eval_PAP_Source";
import SPINNER_LABEL from "@salesforce/label/c.PJN_Eval_PAP_Spinner_Label";
import SUBMIT from "@salesforce/label/c.PJN_Eval_PAP_Submit";
import VALUE from "@salesforce/label/c.PJN_Eval_PAP_Value";

export default class PjnGetPapEligibility extends LightningElement {
    @api recordId;

    papEligibility;
    preview;
    previewRecord;
    submitting = false;
    error;

    labels = {
        CANCEL,
        ERROR,
        FED_POV_LVL_PCT_LABEL: "Federal Poverty Level Percentage", // default
        FINISH,
        FIELD,
        HOUSEHOLD_SIZE_LABEL: "Estimated Household Size", // default
        HOUSEHOLD_INCOME_LABEL: "Estimated Household Income", // default
        MODAL_HEADER,
        OUTCOME_LABEL,
        RESULT,
        SOURCE,
        SPINNER_LABEL,
        SUBMIT,
        VALUE
    };

    @wire(getObjectInfo, { objectApiName: ASSISTANCE_PROG_ELIG_OBJECT })
    handleResponse({data, error}) {
        handleError(error);
        if (data) {
            this.labels.FED_POV_LVL_PCT_LABEL = data.fields.PJN_Federal_Poverty_Level_Percentage__c.label;
            this.labels.HOUSEHOLD_INCOME_LABEL = data.fields.PJN_Estimated_Household_Income__c.label;
            this.labels.HOUSEHOLD_SIZE_LABEL = data.fields.PJN_Estimated_Household_Size__c.label;
        }
    };

    connectedCallback() {
        getPayloadRecord({apeRecordId: this.recordId})
            .then( response => {
                this.previewRecord = response.apeRecord;
                this.preview = Object.keys(response.apeRecord)
                    .filter( field => field !== 'Id')
                    .map( field => {
                        return {
                            label: response.labelMap[field] || field,
                            value: response.apeRecord[field] || '',
                            source: response.sourceMap[field] || ''
                        }
                    }
                );
            })
            .catch( exception => {
                this.error = exception;
            });
    }

    close() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    submit() {
        this.submitting = true;
        getPapEligibility({apeRecord: this.previewRecord})
            .then(response => this.papEligibility = response)
            .catch( exception => this.error = exception)
            .finally(() => this.submitting = false );
    }

    complete() {
        this.dispatchEvent(new CustomEvent('complete'));
    }
}