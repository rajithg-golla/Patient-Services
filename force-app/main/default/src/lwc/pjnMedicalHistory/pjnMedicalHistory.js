import { LightningElement, api, track, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from "lightning/uiRecordApi";
import MED_HISTORY_OBJECT from "@salesforce/schema/PJN_Medical_History__c";
import NEW_LABEL from "@salesforce/label/HealthCloudGA.Button_Label_New";
import getMetricRecTypeId from "@salesforce/apex/PJN_MedicalHistoryCtrl.getMetricRecTypeId";
import handleError from "c/pjnErrorHandler";

const BRAND_VARIANT = "brand";
const NEUTRAL_VARIANT = "neutral";

export default class PjnMedicalHistory extends LightningElement {
    @api recordId;
    @api listRecordsPerPage = 10;
    @api listInitialSortField = "Name";
    @api listInitialSortDirectiton = "asc";
    @api listShowAllForCurrentPatient = false;
    @api showModal = false;

    @track patientId;
    @track selectedRecordTypeId = "";
    @track recordTypes = [];
    @track objectLabel = "";
    @track newButtonLabel = "";
    @track creatingRecord = false;
    @track medHistObjectInfo;

    @wire(getObjectInfo, { objectApiName: MED_HISTORY_OBJECT }) handleResponse(response) {
        handleError(response.error);
        if (response.data) {
            this.medHistObjectInfo = response.data;
            this.objectLabel = response.data.label;
            this.recordTypes = Object.keys(response.data.recordTypeInfos)
                .map( key => {
                    const recordType = Object.assign({}, response.data.recordTypeInfos[key]);
                    recordType.selected = recordType.defaultRecordTypeMapping;
                    recordType.variant = recordType.selected ? BRAND_VARIANT : NEUTRAL_VARIANT;
                    return recordType;
                })
                .filter( recordType => !recordType.master && recordType.available )
                .sort((a,b) => (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0));

            const selected = this.recordTypes.find( recordType => recordType.selected );
            if (selected) {
                this.selectedRecordTypeId = selected.recordTypeId;
                this.newButtonLabel = `${NEW_LABEL} ${selected.name}`;
            }
        }
    }

    @wire(getMetricRecTypeId) metricRecTypeId;

    @wire(getRecord, {recordId: "$recordId", fields: ["Case.AccountId"]})
    setPatientId(response) {
        handleError(response.error);
        if (response.data) {
            this.patientId = response.data.fields.AccountId.value;
        }
    }

    @api
    refreshList() {
        const medHistoryList = this.template.querySelector("c-pjn-medical-history-list");
        if (medHistoryList) {
            medHistoryList.refresh();
        }
    }

    handleRecordTypeClick(event) {
        this.handleModalClose();

        this.recordTypes = this.recordTypes.map(recordType => {

            const updatedRecordType = Object.assign({}, recordType);
            updatedRecordType.variant = NEUTRAL_VARIANT;
            if (updatedRecordType.name === event.target.label) {
                updatedRecordType.variant = BRAND_VARIANT;
                this.selectedRecordTypeId = updatedRecordType.recordTypeId;
                this.newButtonLabel = `${NEW_LABEL} ${updatedRecordType.name}`;
            }
            return updatedRecordType;
        });
    }

    handleNewButtonClick() {
        this.creatingRecord = true;
    }

    handleModalClose() {
        this.creatingRecord = false;
    }

    get showMetrics() {
        return this.selectedRecordTypeId === this.metricRecTypeId.data;
    }

}