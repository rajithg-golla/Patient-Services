/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the Enrollment Response
 */
public with sharing class MVN_ConnectiveRxEnrollResponse {

    /**
     * JSON Parameters from ConnectiveRx Response
     */
    public Boolean success;
    public String requestId;
    public String traceId;
    public String updateStatus;
    public String message;
    public MVN_ConnectiveRxEnrollResult result;
    public List<MVN_ConnectiveRxEnrollError> errors;
}