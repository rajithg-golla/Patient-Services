import { LightningElement, wire, track, api } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMetricGroups from "@salesforce/apex/PJN_MetricsCtrl.getMetricGroups";
import getMetricCountsByGroup from "@salesforce/apex/PJN_MetricsCtrl.getMetricCountsByGroup";
import handleError from "c/pjnErrorHandler";
import LOADING from "@salesforce/label/HealthCloudGA.Msg_Loading";

export default class PjnMetricGroups extends LightningElement {

    @api carePlanId;
    @api patientId;
    @api showAllForCurrentPatient;

    @track metricGroups;
    @track loading = true;
    @track state = {
        selectedGroup: null,
    };

    loadingLabel = LOADING;

    _metricGroups;
    _metricGroupCounts = {};

    @wire(getMetricGroups)
    proceessMetricGroups(response) {
        handleError(response.error);
        if (response.data) {
            this._metricGroups = response.data;
        }
        this.buildWrappers();
    }

    @wire(getMetricCountsByGroup, { patientId: "$patientId", carePlanId: "$carePlanId",showAllForCurrentPatient: "$showAllForCurrentPatient"})
    processMetricGroupCounts(response) {
        handleError(response.error);
        if (response.data) {
            // set directly to response so it can be called by refreshApex
            this._metricGroupCounts = response;
        }
        this.buildWrappers();
    }


    buildWrappers() {
        if (this._metricGroups && this._metricGroupCounts.data) {
            this.metricGroups = this._metricGroups.map( group => {
                const wrapper = {
                    detail: group
                };
                wrapper.count = this._metricGroupCounts.data[group.Id] || 0;
                wrapper.class = wrapper.count ? "has-data" : "";
                return wrapper;
            });
        }
        this.evaluateLoading();
    }

    evaluateLoading() {
        this.loading = !this.metricGroups
            || !this._metricGroups
            || (!this._metricGroupCounts.data && !this._metricGroupCounts.error);
    }

    get selectedGroupId() {
        return this.state.selectedGroup.Id;
    }
    set selectedGroupId(value) {
        this.handleGroupClick({ detail: value });
        const metricTypes = this.template.querySelector("c-pjn-metric-types");
        if (metricTypes) {
            metricTypes.selectedTypeId = null;
        }
    }

    handleGroupClick(event) {
        const selectedGroups = this._metricGroups.filter(
            metricGroup => metricGroup.Id === event.detail
        );
        if (selectedGroups.length) {
            this.state.selectedGroup = selectedGroups[0];
        }
    }

    handleBackClick() {
        this.state.selectedGroup = null;
    }

    refreshCounts() {
        refreshApex(this._metricGroupCounts);
    }
}