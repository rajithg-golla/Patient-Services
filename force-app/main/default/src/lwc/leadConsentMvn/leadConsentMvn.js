import { LightningElement, api, wire } from "lwc";
import createAndSendAgreement from '@salesforce/apex/LeadConsentCtrlMVN.createAndSendAgreement';
import handleError from 'c/pjnErrorHandler';
import getSigningUrl from '@salesforce/apex/LeadConsentCtrlMVN.getSigningUrl';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAgreementDocId from '@salesforce/apex/LeadConsentCtrlMVN.getAgreementDocId';
export default class LeadConsentMvn extends NavigationMixin(LightningElement) {
    @api recordId;
    @api invokeSignInPerson = false;

    submitting = false;
    submittingMessage = '';

    labels = {
        CONSENT_EMAILED: 'Consent Document Emailed',
        GENERATING_AGREEMENT: 'Generating Agreement',
        GETTING_SIGNING_URL: 'Getting Signing Url'
    };

    byEmail() {
        this.submit(false);
    }

    inPerson() {
        this.submit(true);
    }

    async connectedCallback() {
        if (this.invokeSignInPerson) {
            try {
                // called from an agreement object
                this.submitting = true;
                this.submittingMessage = this.labels.GETTING_SIGNING_URL;
                const agreementDocId = await getAgreementDocId({ agreementId: this.recordId});
                const url = await getSigningUrl({agreementId: agreementDocId});
            
                this[NavigationMixin.Navigate]({ 
                    type: 'standard__webPage', 
                    attributes: { url: url }                     
                });
            } catch (error) {
                if (error.body && error.body.message && error.body.message.split('\n').length == 3) {
                    handleError(JSON.parse(error.body.message.split('\n')[2]).message);
                } else {
                    handleError('Unknown Exception. Has this consent already been signed?');
                }
            }            
        }
    }

    async submit(signInPerson) {
        this.submitting = true;
        try {
            this.submittingMessage = this.labels.GENERATING_AGREEMENT;
            const agreementId = await createAndSendAgreement({
                leadId: this.recordId,
                templateName: 'DEDSI Consent',
                signInPerson
            });
            
            if (signInPerson) {
                this.submittingMessage = this.labels.GETTING_SIGNING_URL;
                await this.sleep(5000); // give adobe a chance to build signing URL
                const url = await getSigningUrl({agreementId});
                this[NavigationMixin.Navigate]({ 
                    type: 'standard__webPage', 
                    attributes: { url: url }                     
                });               
            } else {
                this.dispatchEvent( 
                    new ShowToastEvent({
                        message: this.labels.CONSENT_EMAILED,
                        variant: 'success',
                    })
                );
            }

            this.dispatchEvent( new CustomEvent('closequickaction') );
        } catch( error ) {            
            handleError(error);
        } finally {
            this.submitting = false;
            this.submittingMessage = '';
        }
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}