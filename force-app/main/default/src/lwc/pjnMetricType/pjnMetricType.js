import { LightningElement, wire, track, api } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { deleteRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getMetrics from "@salesforce/apex/PJN_MetricsCtrl.getMetrics";
import MED_HIST_OBJECT from "@salesforce/schema/PJN_Medical_History__c";
import handleError from "c/pjnErrorHandler";
import LOADING from "@salesforce/label/HealthCloudGA.Msg_Loading";
import NO_RECORDS from "@salesforce/label/c.PJN_Medical_History_No_Records";
import LIST from "@salesforce/label/c.PJN_Medical_History_List";
import TREND from "@salesforce/label/c.PJN_Medical_History_Trend";
import DELETE_WARNING from "@salesforce/label/c.PJN_Medical_History_Delete_Warning"
import DELETE_LAST_ENTRY from "@salesforce/label/c.PJN_Medical_History_Delete_Last_Entry"


const columns = [
    // placeholder for labels. Updated in processMedHistoryObject function
    { label: "Date", fieldName: "PJN_Date__c", type: "date-locale"},
    { label: "Value", fieldName: "PJN_Value__c", type: "text"},
];

export default class PjnMetricType extends LightningElement {
    @api carePlanId;
    @api patientId;
    @api showAllForCurrentPatient;

    @track columns = columns;
    @track metricTypeId;
    @track metrics;
    @track medicalHistoryInfo;

    labels = {
        LIST,
        LOADING,
        NO_RECORDS,
        TREND,
        DELETE_WARNING,
        DELETE_LAST_ENTRY
    };

    @track selectedView = LIST;

    _metrics;
    _type;

    @wire(getMetrics, { patientId: "$patientId", carePlanId: "$carePlanId", typeId: "$metricTypeId", showAllForCurrentPatient: "$showAllForCurrentPatient"})
    processMetrics(response) {
        handleError(response.error);
        this._metrics = response;
        if (response.data) {
            this.metrics = response.data;
        }
    }

    @wire(getObjectInfo, { objectApiName: MED_HIST_OBJECT })
    processMedHistoryObject(response) {
        handleError(response.error);
        if (response.data) {
            this.medicalHistoryInfo = response.data;
            this.columns = this.columns.map( column => {
                if (response.data.fields[column.fieldName]) {
                    column.label = response.data.fields[column.fieldName].label;
                }
                return column;
            });
        }
    }

    @api
    get metricType() {
        return this._type;
    }
    set metricType(value) {
        this._type = value;
        this.metricTypeId = value.Id;
    }

    get loading() {
        return !this.metrics;
    }

    get displayTrend() {
        return this.metricType.PJN_Show_Trend__c && this.metrics.length > 1;
    }

    get showList() {
        return this.selectedView === LIST;
    }

    get showTrend() {
        return this.selectedView === TREND;
    }

    get listBrand() {
        return this.selectedView === LIST ? "brand" : "neutral"
    }

    get trendBrand() {
        return this.selectedView === TREND ? "brand" : "neutral"
    }

    get lastEntryMenuOptions() {
        let lastEntryMenuOptions = [];
        if (this.medicalHistoryInfo && this.medicalHistoryInfo.deletable) {
            lastEntryMenuOptions.push(
                {
                    "value": "delete",
                    "iconName": "utility:delete",
                    "label": DELETE_LAST_ENTRY
                }
            );
        }
        return lastEntryMenuOptions;
    }

    setShowList() {
        this.selectedView = LIST;
    }

    setShowTrend() {
        this.selectedView = TREND;
    }

    refreshList() {
        this.metrics = null;
        refreshApex(this._metrics);
    }

    handleLastEntryMenuSelect(event) {
        const selectedMenuItemValue = event.detail.value;

        if (selectedMenuItemValue === 'delete') {
            if (confirm(DELETE_WARNING)) {
                deleteRecord(this.metrics[0].Id)
                .then(() => {
                    this.refreshList();
                })
                .catch(error => {
                    handleError(error);
                });
            }
        }
    }
}