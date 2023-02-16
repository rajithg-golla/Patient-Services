import { LightningElement, api } from "lwc";
import SUMMARY from "@salesforce/label/c.PJN_Medical_History_Summary";
import DETAILS from "@salesforce/label/c.PJN_Medical_History_Details";

export default class PjnMetrics extends LightningElement {
    @api carePlanId;
    @api patientId;
    @api showAllForCurrentPatient;

    labels = {
        SUMMARY,
        DETAILS
    };

    handleShowGroupDetail(event) {
        const tabset = this.template.querySelector("lightning-tabset");
        if (tabset) {
            tabset.activeTabValue = "details";
        }

        const metricGroups = this.template.querySelector("c-pjn-metric-groups");
        if (metricGroups) {
            metricGroups.selectedGroupId = event.detail;
        }
    }

    handleNewMetric() {
        this.template.querySelector("c-pjn-metrics-summary").refreshData();
    }
}