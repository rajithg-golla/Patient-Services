import { LightningElement, api, wire, track } from 'lwc';

import syncAccount from '@salesforce/apex/PJN_NetworkAccountSync.syncAccount';

export default class pjnNetworkAccountSync extends LightningElement {

    @api recordId;
    @api fields;
    @track isUpdated;

   connectedCallback() {
        syncAccount({recordId : this.recordId, fields : this.fields}).then(result => {
            this.isUpdated = result;
            console.log('Account sync completed - Updated: ', result);
        })
        .catch(error => {
            console.log("Account sync error message: ", JSON.stringify(this.error));
        });
    }
}