import { LightningElement, api } from "lwc";

export default class PjnCoverageInvestigationSelectPriorAuths extends LightningElement {
    @api memberPlan;
    @api columns;
    @api noRecordLabel;

    get showPriorAuthorizations() {
        return this.memberPlan.selected || this.memberPlan.PJN_Prior_Authorizations__r.some(
            priorAuth => priorAuth.selected || priorAuth.alreadyExists
        );
    }

    addOrRemovePriorAuthorization(event) {
        this.dispatchEvent(
            new CustomEvent(
                'priorauthrowclicked',
                event
            )
        );
    }
}