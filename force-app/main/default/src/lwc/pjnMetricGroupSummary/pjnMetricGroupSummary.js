import { LightningElement, api, wire, track } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getGroupSummary from "@salesforce/apex/PJN_MetricsCtrl.getGroupSummary";
import handleError from "c/pjnErrorHandler";

const columns = [
    { label: "Date", fieldName: "PJN_Date__c", type: "date-locale"},
    { label: "Metric", fieldName: "metricTypeDescription", type: "text"},
    { label: "Value", fieldName: "PJN_Value__c", type: "text"},
];

export default class PjnMetricGroupSummary extends LightningElement {
    @api groupId;
    @api carePlanId;
    @api patientId;
    @api showAllForCurrentPatient;

    @track columns = columns;
    @track latestMetrics = [];

    _groupSummary;

    @wire(getGroupSummary, { patientId: "$patientId", carePlanId: "$carePlanId", groupId: "$groupId", showAllForCurrentPatient: "$showAllForCurrentPatient"})
    processLatesMetrics(response) {
        handleError(response.error);
        if (response.data) {
            this._groupSummary = response;
            this.latestMetrics = response.data.map( metric => {
                const thisMetric = Object.assign({}, metric);
                //flatten the parent field access
                thisMetric.metricTypeDescription = metric.PJN_Metric_Type__r.PJN_Description__c;
                return thisMetric;
            });

        }
    }

    @api
    refreshSummary() {
        refreshApex(this._groupSummary);
    }
}