import { LightningElement, api } from 'lwc';

export default class PjnAccountSearchInputForm extends LightningElement {
    @api objectName;
    @api fieldList;

    /**
     * Return all populated inputs as an array of name:
     */
    @api
    getInputs() {
        const inputs = this.template.querySelectorAll('lightning-input-field');
        const populatedInputs = {};

        Array.from(inputs)
            .filter(input => input.value )
            .forEach( input => populatedInputs[input.fieldName] = input.value);

        return populatedInputs;
    }

    @api
    clear() {
        const inputs = this.template.querySelectorAll('lightning-input-field');
        Array.from(inputs)
            .forEach( input => input.value = null);
    }
}