/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the Enrollment Request
 */
public with sharing class MVN_ConnectiveRxEnrollRequest {

    /**
     * JSON Parameters from ConnectiveRx Request
     */
    public MVN_ConnectiveRxEnrollWorkflow workflow;
    public String groupNumber;
    public MVN_ConnectiveRxEnrollmentWrapper enrollment;

    /**
     * Constructor to populate the request for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     */
    public MVN_ConnectiveRxEnrollRequest(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.workflow = new MVN_ConnectiveRxEnrollWorkflow('Enrollment');
        this.groupNumber = fulfillmentRequest.MVN_Copay_Group_Number__c;
        this.enrollment = new MVN_ConnectiveRxEnrollmentWrapper(fulfillmentRequest);
    }
}