import { LightningElement, api, track, wire } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import INVESTIGATION_OBJECT from "@salesforce/schema/PJN_Coverage_Investigation__c";
import TYPE_FIELD from "@salesforce/schema/PJN_Coverage_Investigation__c.PJN_Type__c";
import retrieveCoverageInvestigationItems from "@salesforce/apex/PJN_CoverageInvestigationHelper.retrieveCoverageInvestigationItems";
import retrieveMemberPlans from "@salesforce/apex/PJN_CoverageInvestigationHelper.retrieveMemberPlans";
import getFieldSet from "@salesforce/apex/PJN_CoverageInvestigationHelper.getFieldSet";
import getInvestigationCarePlanId from "@salesforce/apex/PJN_CoverageInvestigationHelper.getInvestigationCarePlanId";
import createCoverageInvestigationItems from "@salesforce/apex/PJN_CoverageInvestigationHelper.createCoverageInvestigationItems";
import handleError from "c/pjnErrorHandler";
import { NavigationMixin } from "lightning/navigation";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import COVERAGE_INVESTIGATION_TYPE from "@salesforce/label/c.PJN_Coverage_Investigation_Type";
import CREATE from "@salesforce/label/c.PJN_Coverage_Investigation_Create";
import MEMBER_PLANS from "@salesforce/label/c.PJN_Coverage_Investigation_Member_Plans";
import NEW_CI from "@salesforce/label/c.PJN_Coverage_Investigation_New_CI";
import NEXT from "@salesforce/label/c.PJN_Coverage_Investigation_Next";
import NO_MEMBER_PLANS from "@salesforce/label/c.PJN_Coverage_Investigation_No_Member_Plans";
import PREVIOUS from "@salesforce/label/c.PJN_Coverage_Investigation_Previous";
import SELECT_MP from "@salesforce/label/c.PJN_Coverage_Investigation_Select_MP";
import SUBMIT from "@salesforce/label/c.PJN_Coverage_Investigation_Submit";
import UPDATE from "@salesforce/label/c.PJN_Coverage_Investigation_Update";
import UPDATE_CI from "@salesforce/label/c.PJN_Coverage_Investigation_Update_CI";

const selectedRow = {
    selected: true,
    iconName: "utility:check",
    buttonName: "Remove Row",
    variant: "brand"
};

const deselectedRow = {
    selected: false,
    iconName: "utility:add",
    buttonName: "Add Row",
    variant: "border"
};

const alreadyExists = {
    alreadyExists: true,
    selected:true,
    iconName: "utility:check",
    buttonName: "Currently Selected",
    variant: "container"
};

const actionColumn = {
    label: "Action",
    type: "button-icon",
    typeAttributes: {
        name: "selection",
        iconName: {fieldName: "iconName"},
        disabled: {fieldName: "alreadyExists"},
        title: {fieldName: "buttonName"},
        variant: {fieldName: "variant"}
    },
    fixedWidth: 80
};

export default class PjnCoverageInvestigationItemSelector extends NavigationMixin(LightningElement) {
    @api carePlanId;
    @api investigationId;
    @api openInNewTab = false;

    loading = true;

    currentInvestigationItemLookupIds = [];

    @track memberPlans = [];
    defaultRecTypeId;
    typePicklistValues = [];
    selectedType = "PJN_Initial_Investigation";

    columns = {
        memberPlans: []
    };

    labels = {
        COVERAGE_INVESTIGATION_TYPE,
        CREATE,
        MEMBER_PLANS,
        NEW_CI,
        NEXT,
        NO_MEMBER_PLANS,
        PREVIOUS,
        SELECT_MP,
        SUBMIT,
        UPDATE,
        UPDATE_CI
    };

    page = 1;

    async connectedCallback() {
        if (this.investigationId) {
            if (!this.carePlanId) {
                this.carePlanId = await getInvestigationCarePlanId({ investigationId: this.investigationId});
            }
            this.page = 2;
            await this.refreshCoverageInvestigationItems();
        } else {
            this.openInNewTab = true;
        }

        await this.refreshMemberPlans();
        this.loading = false;
    }

    get showTypeSelection() { return this.page === 1; }
    get showMemberPlanSelection() { return this.page === 2;}

    get isInitial() { return this.selectedType === "PJN_Initial_Investigation"; }
    get title() {
        if (this.investigationId) {
            return this.labels.UPDATE_CI;
        }
        return this.labels.NEW_CI;
    }

    get createOrUpdate() {
        if (this.investigationId) {
            return this.labels.UPDATE;
        }
        return this.labels.CREATE;
    }

    async nextPage() {
        this.page++;
        if (this.showMemberPlanSelection) {
            this.loading = true;
            console.log("refreshing");
            await this.refreshMemberPlans();
            this.loading = false;
        }
    }

    previousPage() {
        this.page--;
    }

    @wire(getObjectInfo, { objectApiName: INVESTIGATION_OBJECT })
    handleInvestigationObject({ error, data }) {
        handleError(error);
        if (data) {
            this.defaultRecTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$defaultRecTypeId", fieldApiName: TYPE_FIELD })
    handleTypePicklistValues({error, data}) {
        handleError(error);
        if (data) {
            this.typePicklistValues = data.values;
        }
    }

    setType(event) {
        this.selectedType = event.detail.value;
    }

    @wire(getFieldSet)
    handleFieldSet({error, data}) {
        handleError(error);
        if (data) {
            this.columns = { memberPlans: [actionColumn, ...data] };
        }
    }

    async refreshCoverageInvestigationItems() {
        try {
            const data = await retrieveCoverageInvestigationItems({investigationId: this.investigationId});
            if (data) {
                this.currentInvestigationItemLookupIds = data.map( item => item.PJN_Member_Plan__c);
            }
            return Promise.resolve();
        } catch (error) {
            handleError(error);
        }
    }

    async refreshMemberPlans() {
        try {
            const data = await retrieveMemberPlans({carePlanId : this.carePlanId});
            if (data) {
                this.memberPlans = data.map( immutableMemberPlan => {
                    const memberPlan = Object.assign({}, immutableMemberPlan);

                    if (this.isInitial && memberPlan.PJN_Active__c) {
                        Object.assign(memberPlan, selectedRow);
                    } else {
                        Object.assign(memberPlan, deselectedRow);
                    }

                    if (this.currentInvestigationItemLookupIds.includes(memberPlan.Id)) {
                        Object.assign(memberPlan, alreadyExists);
                    }

                    return memberPlan;
                });
            }
            return Promise.resolve();
        } catch (error) {
            handleError(error);
        }
    }

    addOrRemoveMemberPlan(event) {
        if (event.detail.row.alreadyExists) {
            return;
        }
        const rowId = event.detail.row.Id;
        let rowAction = selectedRow;
        if (event.detail.row.selected) {
            rowAction = deselectedRow; // already selected so deselect it
        }
        this.memberPlans = this.memberPlans.map( memberPlan => {
            if (memberPlan.Id === rowId) {
                Object.assign(memberPlan, rowAction);
            }
            return memberPlan;
        });
    }

    async submit() {
        try {
            this.loading = true;
            const selectedMemberPlans = this.memberPlans.filter(
                memberPlan => memberPlan.selected && !memberPlan.alreadyExists
            );
            const selectedMemberPlanIds = selectedMemberPlans.map( memberPlan => memberPlan.Id);

            const investigationId = await createCoverageInvestigationItems({
                coverageInvestigation: {
                    Id: this.investigationId,
                    PJN_Care_Plan__c: this.carePlanId,
                    PJN_Type__c: this.selectedType
                },
                memberPlanIds: selectedMemberPlanIds,
            });

            if (this.openInNewTab) {
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: investigationId,
                        objectApiName: "PersonAccount",
                        actionName: "view"
                    }
                }, true);

            } else {
                this.dispatchEvent( new CustomEvent( "refreshtab" ));
            }

            getRecordNotifyChange([{recordId: this.investigationId}, {recordId: this.carePlanId}]);
        } catch (error) {
            handleError();
            this.loading = false;
        }
    }
}