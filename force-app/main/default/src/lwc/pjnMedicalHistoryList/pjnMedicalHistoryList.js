import { LightningElement, wire, api, track } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { CurrentPageReference } from "lightning/navigation";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { NavigationMixin } from "lightning/navigation";
import getMedicalHistory from "@salesforce/apex/PJN_MedicalHistoryCtrl.getMedicalHistory";
import handleError from "c/pjnErrorHandler";
import NO_RECORDS from "@salesforce/label/c.PJN_Medical_History_No_Records";
import PREVIOUS from "@salesforce/label/HealthCloudGA.Link_Pagination_Previous";
import NEXT from "@salesforce/label/HealthCloudGA.Link_Pagination_Next";
import LOADING from "@salesforce/label/HealthCloudGA.Msg_Loading";
import PAGE_X_OF_Y from "@salesforce/label/c.PJN_Medical_History_Page_X_of_Y";
import VIEW_DETAILS from "@salesforce/label/c.PJN_Medical_History_View_Details";

const columns = [
    { label: "", fieldName: "Name", type: "text", sortable: true},
    { label: "", fieldName: "PJN_Details__c", sortable: true},
    { label: "", fieldName: "PJN_Dates_Formula__c", sortable: true },
    { type: "action", typeAttributes: { rowActions: [{ label: VIEW_DETAILS, name: "show_details" }], menuAlignment: "auto" } }
];

export default class PjnMedicalHistoryList extends NavigationMixin(LightningElement) {
    @api carePlanId;
    @api rowsPerPage = 5;
    @api initialSortField;
    @api initialSortDirection;
    @api showAllForCurrentPatient;

    @track columns = columns;
    @track page;
    @track totalPages;
    @track records;
    @track pageXofY;
    @track sortDirection;
    @track sortField;

    labels = {
        LOADING,
        NO_RECORDS,
        NEXT,
        PREVIOUS
    };

    _allRecords;
    _medHistObjectInfo;
    _recordTypeId;
    _wiredRecords;

    @wire(CurrentPageReference) pageRef;

    @wire(getMedicalHistory, { carePlanId: "$carePlanId", recordTypeId: "$_recordTypeId", showAllForCurrentPatient: "$showAllForCurrentPatient" })
    processRecords(response) {
        handleError(response.error);
        this.rowsPerPage = parseInt(this.rowsPerPage, 10); // design time param, may be string, convert to int
        this._wiredRecords = response; // store for refreshApex call
        this.sortField = this.initialSortField;
        this.sortDirection = this.initialSortDirection;
        this.page = 1;
        if (response.data) {
            const data = Object.assign({}, response.data);
            this._allRecords = Object.values(data);
            this.totalPages = Math.ceil(this._allRecords.length / this.rowsPerPage);
            this.sortAllRecords();
        }
    }

    @api
    refresh() {
        refreshApex(this._wiredRecords);
    }

    @api
    get recordTypeId() {
        return this._recordTypeId;
    }
    set recordTypeId(value) {
        this.records = null;
        this._recordTypeId = value;
    }

    @api
    get medHistObjectInfo() {
        return this._medHistObjectInfo;
    }
    set medHistObjectInfo(value) {
        this._medHistObjectInfo = value;
        if (value) {
            this.columns = this.columns.map( column => {
                if (value.fields[column.fieldName]) {
                    column.label = value.fields[column.fieldName].label;
                }
                return column;
            });
        }
    }

    setRecords() {
        const start = (this.page - 1) * this.rowsPerPage;
        const end = start + this.rowsPerPage;
        this.records = this._allRecords.slice(start, end);
        this.pageXofY = PAGE_X_OF_Y.replace("{0}", this.page).replace("{1}", this.totalPages);
    }

    sortAllRecords() {
        this._allRecords.sort(
            (recordA, recordB) => {
                const aValue = recordA[this.sortField] || "";
                const bValue = recordB[this.sortField] || "";

                if (this.sortDirection === "asc") {
                    return aValue.localeCompare(bValue);
                }
                return bValue.localeCompare(aValue);
            }
        );
        this.setRecords();
    }

    handleSort(event) {
        this.page = 1;
        if (this.sortField !== event.detail.fieldName) {
            this.sortField = event.detail.fieldName;
            this.sortDirection = "asc";
        } else {
            this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
        }
        this.sortAllRecords();
    }

    get hasRecords() {
        return this.records.length;
    }

    get disableNext() {
        return this._allRecords && (this.page-1) * this.rowsPerPage + this.rowsPerPage >= this._allRecords.length;
    }

    get disablePrevious() {
        return this.page <= 1;
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get loading() {
        return !this.records;
    }


    handleNext() {
        this.page++;
        this.setRecords();
    }

    handlePrevious() {
        this.page--;
        this.setRecords();
    }

    connectedCallback() {
        registerListener("newrecordcreated", this.refresh, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleRowAction(evt) {
        const row = evt.detail.row;
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: row.Id,
                actionName: "view"
            },
        });

    }
}