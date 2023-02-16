import { LightningElement, wire } from 'lwc';
import getPrograms from '@salesforce/apex/PJN_ProgramBuilderCtrl.getPrograms';
import handleError from 'c/pjnErrorHandler';

export default class PjnProgramBuilder extends LightningElement {

    programs = [];
    selectedProgram;

    @wire(getPrograms)
    handlePrograms({data, error}) {
        handleError(error);
        if (data) {
            this.programs = data;
        }
    }

    handleProgramSelection(event) {
        this.selectedProgram = event.target.value;
    }
}