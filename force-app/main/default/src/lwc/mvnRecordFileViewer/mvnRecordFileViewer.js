import { LightningElement, api} from 'lwc';
import getRecordFiles from '@salesforce/apex/MVN_RecordFileViewerCtrl.getRecordFiles';
import { setSelfVariable, doApexCall, hideSpinner } from 'c/mvnProxyService';
import {NavigationMixin} from 'lightning/navigation';

export default class MvnRecordFileViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    files = [];
    countOfFiles;
    hasUserPermissions;
    isLoaded = false;

    connectedCallback() {
        setSelfVariable(this);
        this.getRecordFiles();
    }

    getRecordFiles() {
        doApexCall(getRecordFiles({recordId : this.recordId}))
            .then(result => {
                this.hasUserPermissions = result.hasUserPermissions;
                this.files = result.recordFileWrappers;
                this.countOfFiles = result.countOfFiles;
                this.isLoaded = true;
                hideSpinner();
            });
    }

    previewHandler(event) {
        this.dispatchEvent(new CustomEvent('preview', { detail: { docId: event.target.dataset.id } }));
    }
}