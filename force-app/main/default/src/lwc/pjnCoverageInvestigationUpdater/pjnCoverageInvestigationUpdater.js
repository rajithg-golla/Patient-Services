import { LightningElement, api } from "lwc";
import getTable from "@salesforce/apex/PJN_CoverageInvestigationUpdaterCtrl.getTable";
import getFields from "@salesforce/apex/PJN_CoverageInvestigationUpdaterCtrl.getFields";
import getTherapyAccessRecTypeId from "@salesforce/apex/PJN_CoverageInvestigationUpdaterCtrl.getTherapyAccessRecTypeId";
import submit from "@salesforce/apex/PJN_CoverageInvestigationUpdaterCtrl.submit";
import handleError from "c/pjnErrorHandler";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import ACTIONS from "@salesforce/label/c.PJN_Update_CI_Actions";
import ACTIONS_SUBHEADER from "@salesforce/label/c.PJN_Update_CI_Actions_Subheader";
import ACTIVITY_ACTION from "@salesforce/label/c.PJN_Update_CI_Activity_Create_Header";
import ACTIVITY_ACTION_SUB from "@salesforce/label/c.PJN_Update_CI_Activity_Create_Header_Sub";
import ASSISTANCE_PROGRAMS from "@salesforce/label/c.PJN_Update_CI_Assistance_Programs";
import CANCEL from "@salesforce/label/c.PJN_Update_CI_Cancel";
import HEADER from "@salesforce/label/c.PJN_Update_CI_Modal_Header";
import INVESTIGATON_ACTION from "@salesforce/label/c.PJN_Update_CI_Investigation_Action";
import INVESTIGATON_ACTION_SUB from "@salesforce/label/c.PJN_Update_CI_Investigation_Action_Sub";
import MEMBER_PLANS from "@salesforce/label/c.PJN_Update_CI_Update_Member_Plans";
import PRIOR_AUTHORIZATIONS from "@salesforce/label/c.PJN_Update_CI_Prior_Auths_Header";
import SAVE from "@salesforce/label/c.PJN_Update_CI_Update_Save";
import THERAPY_ACCESS_ACTION from "@salesforce/label/c.PJN_Update_CI_Therapy_Access_Header";
import THERAPY_ACCESS_ACTION_SUB from "@salesforce/label/c.PJN_Update_CI_Therapy_Access_Header_Sub";

export default class PjnCoverageInvestigationUpdater extends LightningElement {
    // intake the investigation id
    @api investigationId;

    loading = true;

    // child record data table variables
    memberPlans = { data: []};
    priorAuths = { data: []};
    assistancePrograms = { data: []};

    // update/create fields lists
    fields = {
        investigation: [],
        cases: [],
        event: []
    };

    // object create/update tracking. fields here are written from the form
    objects = {
        investigation: {},
        case: {},
        event: {}
    };

    updateInvestigation = false;
    createEvent = false;
    createCase = false;
    therapyAccessRecTypeId;

    labels = {
        ACTIONS,
        ACTIONS_SUBHEADER,
        ACTIVITY_ACTION,
        ACTIVITY_ACTION_SUB,
        ASSISTANCE_PROGRAMS,
        CANCEL,
        HEADER,
        INVESTIGATON_ACTION,
        INVESTIGATON_ACTION_SUB,
        MEMBER_PLANS,
        PRIOR_AUTHORIZATIONS,
        SAVE,
        THERAPY_ACCESS_ACTION,
        THERAPY_ACCESS_ACTION_SUB
    }

    async connectedCallback() {
        try {
            // assign the outcome of the promises to the appropriate variables
            [
                this.memberPlans,
                this.priorAuths,
                this.assistancePrograms,
                this.fields.investigation,
                this.fields.case,
                this.fields.event,
                this.therapyAccessRecTypeId
            ] = await Promise.all([
                getTable({investigationId: this.investigationId, childObjectApiName: "PJN_Member_Plan__c"}),
                getTable({investigationId: this.investigationId, childObjectApiName: "PJN_Prior_Authorization__c"}),
                getTable({investigationId: this.investigationId, childObjectApiName: "PJN_Assistance_Program__c"}),
                getFields({objectApiName: "PJN_Coverage_Investigation__c"}),
                getFields({objectApiName: "Case"}),
                getFields({objectApiName: "PJN_Event__c"}),
                getTherapyAccessRecTypeId()
            ]);

            Object.keys(this.fields).forEach( key => {
                this.fields[key] = this.fields[key].map( field => {
                    return field;
                });
            });
            console.log("this.fields",JSON.parse(JSON.stringify(this.fields)));
        } catch (exception) {
            handleError(exception);
        } finally {
            this.loading = false;
        }
    }

    checkFields(event) {
        let value;
        if(event.target.type === "checkbox" || event.target.type === "checkbox-button" || event.target.type === "toggle"){
            value = event.target.checked;
        }else{
            value = event.target.value;
        }

        // any input that calls checkFields must be enclosed in a lightning-layout with a data-id attribute
        const objectWrapper = event.target.closest("lightning-layout").dataset.id;

        // each input that calls checkFields should have a data-fieldname attribute
        const fieldname = event.target.dataset.fieldname;

        if (value) {
            // add the value to the objects fields
            this.objects[objectWrapper][fieldname] = value;
        } else {
            // remove the field from the object keys
            delete this.objects[objectWrapper][fieldname];
        }

        // update the count of fields in each object
        this.investigationFieldCount = Object.keys(this.objects.investigation).length;

        this.template.querySelectorAll("input").forEach( input => input.blur());
        console.log("label",JSON.parse(JSON.stringify(this.template.querySelectorAll(".slds-has-error"))));
    }

    toggleUpdateInvestigation() {
        this.updateInvestigation = !this.updateInvestigation;
        this.objects.investigation = {};
    }
    toggleCreateEvent() {
        this.createEvent = !this.createEvent;
        this.objects.event = {};
    }
    toggleCreateCase() {
        this.createCase = !this.createCase;
        this.objects.case = {};
    }

    cancel() {
        this.dispatchEvent( new CustomEvent("closemodal") );
    }

    complete() {
        this.dispatchEvent( new CustomEvent("complete") );
    }

    async submit() {
        const payload = {};
        let successMessage = "";

        let invalid = [];
        if (this.updateInvestigation) {
            if (!this.valid("investigation")) {
                invalid.push(this.labels.INVESTIGATON_ACTION);
            }
            payload["PJN_Coverage_Investigation__c"] = Object.assign(this.objects.investigation, {Id: this.investigationId});
            successMessage = "updated coverage investigation";
        }
        if (this.createCase) {
            if (!this.valid("case")) {
                invalid.push(this.labels.ACTIVITY_ACTION);
            }
            payload["Case"] = Object.assign(
                this.objects.case,
                {sobjectType: "Case", PJN_Coverage_Investigation__c: this.investigationId}
            );
            successMessage += (successMessage.length ? "," : "") + "created follow-up activity";
        }
        if (this.createEvent) {
            if (!this.valid("event")) {
                invalid.push(this.labels.THERAPY_ACCESS_ACTION);
            }
            payload["PJN_Event__c"] = Object.assign(
                this.objects.event,
                {sobjectType: "PJN_Event__c", PJN_Coverage_Investigation__c: this.investigationId}
            );
            successMessage += (successMessage.length ? "," : "") + "created therapy access record";
        }

        if (invalid.length) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Missing Required Fields",
                    message: `The following actions are missinig requried fields: ${invalid}` ,
                    variant: "warning"
                })
            );
            return;
        }
        if (Object.keys(payload).length) {
            try {
                this.loading = true;
                await submit({data: payload});
                this.complete();
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: "Successfully " + successMessage,
                        variant: "success"
                    })
                );
            } catch (error) {
                console.log("error",JSON.parse(JSON.stringify(error)));
                handleError(error);
            } finally {
                this.loading = false;
            }
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "No Data",
                    message: "Unable to save. No data has been added or changed",
                    variant: "warning"
                })
            );
        }
    }

    valid(objName) {
        const fields = this.fields[objName].filter(field => field.required);
        let valid = true;
        fields.forEach( field => {
            console.log(this.objects[objName][field.name]);
            if (!this.objects[objName][field.name]) {
                valid = false;
            }
        });
        return valid;
    }
}