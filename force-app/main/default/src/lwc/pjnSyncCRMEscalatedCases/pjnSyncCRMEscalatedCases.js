import { LightningElement, api, wire, track } from 'lwc';

import syncEscalatedCases from '@salesforce/apex/PJN_CRMToCaseSync.syncEscalatedCases';

export default class pjnVeevaCRMSuggestionSync extends LightningElement {

    @api recordId;
    @track isUpdated;

   connectedCallback() {
        syncEscalatedCases({recordId : this.recordId}).then(result => {
            this.isUpdated = result;
            console.log('CRM sync completed - Updated: ', result);
        })
        .catch(error => {
            console.log("CRM sync error message: ", JSON.stringify(this.error));
        });
    }
}