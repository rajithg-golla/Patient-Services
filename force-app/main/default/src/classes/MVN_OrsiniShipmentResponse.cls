/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Shipment Response
 */
global with sharing class MVN_OrsiniShipmentResponse {

    /**
     * JSON parameters for the Orsini Shipment API Response
     */
    public String status;
    public String message;
    public List<MVN_OrsiniShipmentResult> shipments;
}