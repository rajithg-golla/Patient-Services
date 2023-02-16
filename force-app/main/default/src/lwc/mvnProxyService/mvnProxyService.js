import { ShowToastEvent } from "lightning/platformShowToastEvent";

export {
    setSelfVariable,
    doApexCall,
    showSpinner,
    hideSpinner,
    showSuccessMessage,
    showErrorMessage
}

let self;

const setSelfVariable = (thisVariable) => {
    self = thisVariable;
}

const doApexCall = (callbackFunction) => {
    showSpinner();
    callbackFunction.catch(error => {
        hideSpinner();
        showErrorMessage((error.body.message.includes('|')) ? error.body.message.split('|')[0] : error.body.message);
    });

    return callbackFunction;
}

const showSpinner = () => {
    self.spinnerClass = 'slds-show';
}

const hideSpinner = () => {
    self.spinnerClass = 'slds-hide';
}

const showSuccessMessage = (message) => {
    self.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            variant: 'success',
            message: message
        })
    );
}

const showErrorMessage = (message) => {
    self.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            variant: 'error',
            message: message
        })
    );
}