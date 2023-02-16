/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Event Result
 */
public with sharing class MVN_OrsiniEventResult {

    /**
     * JSON Parameters for the event result
     */
    public String hub_patient_id;
    public String event_id;
    public Boolean success;
    public String message;
}