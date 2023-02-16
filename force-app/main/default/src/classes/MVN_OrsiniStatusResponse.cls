/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Status Response
 */
global with sharing class MVN_OrsiniStatusResponse {

    /**
     * JSON parameters for the Orsini Status API Response
     */
    public String status;
    public String message;
    public List<MVN_OrsiniEventResult> events;
}