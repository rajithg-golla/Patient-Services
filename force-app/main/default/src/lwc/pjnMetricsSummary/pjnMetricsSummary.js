import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMetricGroups from "@salesforce/apex/PJN_MetricsCtrl.getMetricGroups";
import getMetricCountsByGroup from "@salesforce/apex/PJN_MetricsCtrl.getMetricCountsByGroup";
import handleError from "c/pjnErrorHandler";
import NO_RECORDS from "@salesforce/label/c.PJN_Medical_History_No_Records";
import LOADING from "@salesforce/label/HealthCloudGA.Msg_Loading";
import VIEW_DETAILS from "@salesforce/label/c.PJN_Medical_History_View_Details";

export default class PjnMetricsSummary extends LightningElement {

    @api carePlanId;
    @api patientId;
    @api showAllForCurrentPatient;

    @track groups;
    @track loading = true;

    labels = {
        NO_RECORDS,
        LOADING,
        VIEW_DETAILS
    };

    _groups = {};
    _groupSummaries = {};
    _openSections = [];

    @wire(getMetricCountsByGroup, {patientId: "$patientId", carePlanId: "$carePlanId",showAllForCurrentPatient: "$showAllForCurrentPatient"})
    processSummaries(response) {
        handleError(response.error);
        if (response.data) {
            this._groupSummaries = response;
        }
        this.filterGroups();
    }

    @wire(getMetricGroups)
    processGroups(response) {
        handleError(response.error);
        if (response.data) {
            this._groups = response;
        }
        this.filterGroups();
    }

    filterGroups() {
        if (this._groups.data && this._groupSummaries.data) {
            this.groups = this._groups.data
                .filter( group => this._groupSummaries.data[group.Id])
                .map( group => {
                    return {
                        detail: group,
                        open: this._openSections.includes(group.Id)
                    };
                });
        }
        this.evaluateLoading();
    }

    evaluateLoading() {
        this.loading = !this.groups
            || (!this._groupSummaries.data && !this._groupSummaries.error)
            || (!this._groups.data && !this._groups.error);
    }


    @api
    refreshData() {
        refreshApex(this._groupSummaries);
        refreshApex(this._groups);
        this.template.querySelectorAll("c-pjn-metric-group-summary").forEach(
            groupSummary => groupSummary.refreshSummary()
        );
    }

    handleSectionToggle(event) {
        this._openSections = event.detail.openSections;
        this.groups = this.groups.map( group => {
            group.open = event.detail.openSections.includes(group.detail.Id);
            return group;
        });
    }

    handleButtonIconClick(event) {
        if (event.currentTarget.dataset.groupId) {
            this.dispatchEvent(
                new CustomEvent("showgroupdetail", { detail: event.currentTarget.dataset.groupId })
            );
        }
    }
}