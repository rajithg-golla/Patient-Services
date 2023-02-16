import { LightningElement, wire, track, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import getMetricTypes from "@salesforce/apex/PJN_MetricsCtrl.getMetricTypes";
import getMetricCountsByType from "@salesforce/apex/PJN_MetricsCtrl.getMetricCountsByType";
import handleError from "c/pjnErrorHandler";

export default class PjnMetricTypes extends LightningElement {
    @api carePlanId;
    @api groupId;
    @api patientId;
    @api showAllForCurrentPatient;

    @track metricTypes;
    @track state = {
        selectedType: null
    };

    _metricTypes;
    _metricTypeCounts = {};

    @wire(getMetricTypes, { groupId: "$groupId"})
    processMetricTypes(response) {
        handleError(response.error);
        if (response.data) {
            this._metricTypes = response.data;
        }
        this.buildWrappers();
    }

    @wire(getRecord, { recordId: "$groupId", fields: ["PJN_Metric_Group__c.Name"]})
    group;

    @wire(getMetricCountsByType, { patientId: "$patientId", carePlanId: "$carePlanId", groupId: "$groupId", showAllForCurrentPatient: "$showAllForCurrentPatient"})
    processMetricTypeCounts(response) {
        if (response.data) {
            // set directly to response so it can be called by refreshApex
            this._metricTypeCounts = response;
        }
        this.buildWrappers();
    }

    buildWrappers() {
        if (this._metricTypes && this._metricTypeCounts.data) {
            this.metricTypes = this._metricTypes.map( type => {
                const wrapper = {
                    detail: type
                };
                wrapper.count = this._metricTypeCounts.data[type.Id] || 0;
                wrapper.class = wrapper.count ? "has-data" : "";
                return wrapper;
            });
        }
    }

    @api
    get selectedTypeId() {
        return this.state.selectedType.Id;
    }
    set selectedTypeId(value) {
        this.handleTypeClick({ detail: value});
    }

    handleTypeClick(event) {
        const selectedTypes = this._metricTypes.filter(
            metricType => metricType.Id === event.detail
        );
        if (selectedTypes.length) {
            this.state.selectedType = selectedTypes[0];
        } else {
            this.state.selectedType = null;
        }
    }

    handleTypeBackClick() {
        this.state.selectedType = null;
    }

    handleGroupBackClick() {
        this.dispatchEvent(new CustomEvent("backtogroups"));
    }

    refreshCounts() {
        refreshApex(this._metricTypeCounts);
    }
}