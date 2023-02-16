/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Shipment Request
 */
public with sharing class MVN_OrsiniShipmentRequest {

    /**
     * JSON parameters from Orsini Request
     */
    public String unique_id;
    public String sp_patient_id;
    public String dispense_type;
    public Date dispense_date;
    public Date next_fill_date;
    public String ndc;
    public String product_description;
    public Integer quantity_dispensed;

    /**
     * Get Shipment SFDC record using Orsini Shipment parameters
     * @param carePlan  CarePlan record to be related to
     * @return  `PJN_Shipment__c`
     */
    public PJN_Shipment__c getShipment(Case carePlan) {
        return new PJN_Shipment__c (
            PJN_Order_Id__c = this.unique_id,
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Patient__c = carePlan.AccountId,
            PJN_SP_Patient_ID__c = this.sp_patient_id,
            PJN_Dispense_Type__c = this.dispense_type,
            PJN_Date_Shipped__c = this.dispense_date,
            MVN_Next_Fill_Date__c = this.next_fill_date,
            PJN_NDC__c = this.ndc,
            PJN_Product_Description__c = this.product_description,
            PJN_Quantity_Dispensed__c = this.quantity_dispensed
        );
    }
}