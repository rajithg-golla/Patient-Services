import { LightningElement, api, wire  } from 'lwc';

import getMissingInformationFields from '@salesforce/apex/PJN_CaseMissingInformationCtrl.getMissingInformationFields';
import MISSING_INFORMATION_FIELDS_TITLE from '@salesforce/label/c.PJN_Missing_Information_Fields_Title';
import MISSING_INFORMATION_NO_FIELDS_FOUND from '@salesforce/label/c.PJN_Missing_Information_No_Fields_Found';
import handleError from "c/pjnErrorHandler";
import { refreshApex } from "@salesforce/apex";

export default class PjnCaseMissingInformation extends LightningElement {

    @api recordId;
    apexResponse;

    missingInfoFields;
    missingInfoFieldsEmpty;

    missingInfoFieldsTitle = MISSING_INFORMATION_FIELDS_TITLE;
    missingInfoNoFieldsFound = MISSING_INFORMATION_NO_FIELDS_FOUND;

    @wire(getMissingInformationFields, {recordId: "$recordId"})
    handleVisualization(response) {
        this.apexResponse = response;
        const {data, error} = response;
        handleError(error);
        if (data) {
            this.missingInfoFields = data;
            this.missingInfoFieldsEmpty = data.length === 0;
            console.log("missingInfoFields", data);
        }
    }

    @api
    refresh(){
        refreshApex(this.apexResponse);
    }
}