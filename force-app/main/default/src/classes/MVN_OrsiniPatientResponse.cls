/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Patient Response
 */
global without sharing class MVN_OrsiniPatientResponse {

    /**
     * JSON parameters for the Orsini Patient API Response
     */
    public List<MVN_OrsiniPatientFulfillment> fulfillments;
    public String status;
    public String message;
}