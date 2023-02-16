import { LightningElement, api, wire } from "lwc";
import getProgramVisualizationString from "@salesforce/apex/PJN_ProgramBuilderCtrl.getProgramVisualizationString";
import handleError from "c/pjnErrorHandler";

export default class PjnProgramVisualizer extends LightningElement {

    @api programId;

    flowCharts;

    @wire(getProgramVisualizationString, {programId: "$programId"})
    handleVisualization({data, error}) {
        handleError(error);
        if (data) {
            this.flowCharts = data;
             console.log("flowCharts", data);
        }
    }
}