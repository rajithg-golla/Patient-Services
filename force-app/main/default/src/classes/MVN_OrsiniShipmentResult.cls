/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Shipment Result
 */
public with sharing class MVN_OrsiniShipmentResult {

    /**
     * JSON Parameters for the event result
     */
    public String sp_patient_id;
    public String shipment_id;
    public Boolean success;
    public String message;
}