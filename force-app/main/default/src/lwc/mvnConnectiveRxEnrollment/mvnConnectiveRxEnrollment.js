import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEnrollment from '@salesforce/apex/MVN_ConnectiveRxEnrollment.sendEnrollment';

export default class mvnConnectiveRxEnrollment extends LightningElement {
    @api recordId;
    connectedCallback() {
        sendEnrollment({ recordId: this.recordId }).then(response => {
            this.responseMap = JSON.parse(JSON.stringify(response));
            if (this.responseMap.success) {
                this.showToast('Success',this.responseMap.message,'success','dismissable');
            } else {
                this.showToast('Error',this.responseMap.message,'error','sticky');
            }
        }).catch(error => {
            console.log('Error: ' +error.body.message);
            this.showToast('Error',error.body.message,'error','sticky');
        }).finally(() => {
            const closeQA = new CustomEvent('close')
            this.dispatchEvent(closeQA);
        });
    }

    showToast(title,errorMessage,variant,mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}