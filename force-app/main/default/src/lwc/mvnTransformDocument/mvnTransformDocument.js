import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getFilesRelated from '@salesforce/apex/MVN_TransformDocumentCtrl.getFilesRelated';
import createDocumentData from '@salesforce/apex/MVN_TransformDocumentCtrl.createDocumentData';
import NO_FOUND_MESSAGE from "@salesforce/label/c.MVN_Transform_Document_No_Found";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import handleError from "c/pjnErrorHandler";

const columns = [
    { label: "Title", fieldName: "Title", type: "text", sortable: true},
    { label: "Type", fieldName: "FileType", type: "text", sortable: true},
    { label: "Description", fieldName: "Description", type: "text", sortable: true},
    { type: "action", typeAttributes: { rowActions: [{ label: 'Transform', name: "transform_document" }], menuAlignment: "auto" } }
];

export default class MvnTransformDocument extends NavigationMixin(LightningElement) {

    @api recordId;
    files;
    filesEmpty;
    columns = columns;
    flaggedToClose = false;
    foundResults = false;

    renderedCallback() {
        if (this.flaggedToClose) {
            this.closeAction();
        }
        if (!this.foundResults && this.recordId) {
            getFilesRelated({ recordId: this.recordId})
            .then((result) => {
                this.files = result;
                this.filesEmpty = result.length === 0;
                if (result && result.length === 0) {
                    this.showToast('Error',NO_FOUND_MESSAGE,'error','dismissable');
                    this.closeAction();
                } else if (result) {
                    this.foundResults = true;
                }
            })
            .catch((error) => {
                handleError(error);
            });
        }
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

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'transform_document':
                createDocumentData({ caseId: this.recordId, document: row })
                .then((result) => {
                    this.navigateToVFPage(row, result);
                })
                .catch((error) => {
                    handleError(error);
                });
                break;
        }
    }

    navigateToVFPage(row, result) {
        let subTabURL = '/lightning/cmp/industries_common%3AdocumentWorkspace?';
        subTabURL += 'uid=' + row.ContentDocumentId + '&';
        subTabURL += 'c__recordId=' + row.ContentDocumentId + '&';
        subTabURL += '&ws='+encodeURIComponent(window.location.pathname+'?count=1')+'';
        console.log('Subtab: ' + subTabURL);
        this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
            if (isConsole) {
                this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
                    this.invokeWorkspaceAPI('openSubtab', {
                        parentTabId: focusedTab.parentTabId != null ? focusedTab.parentTabId : focusedTab.tabId,
                        url: subTabURL,
                        focus: true
                    }).then(tabId => {
                        console.log("SubTab ID: ", tabId);
                        this.invokeWorkspaceAPI('setTabLabel', {
                            tabId: tabId,
                            label: 'Transform Document'
                        });
                    }).catch(function (err) {
                        console.log(err);
                    });
                });
            }
        });
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        } else {
                            return resolve(response);
                        }
                    }
                }
            });

            window.dispatchEvent(apiEvent);
        });
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}