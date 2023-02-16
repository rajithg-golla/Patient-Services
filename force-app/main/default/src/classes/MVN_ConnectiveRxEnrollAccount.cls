/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper Connective Rx Enrollment Business Account
 */
public with sharing class MVN_ConnectiveRxEnrollAccount {

    /**
     * JSON Parameters requesting into ConnectiveRx Enrollment
     */
    public String partnerId;
    public String name;
    public String address1;
    public String address2;
    public String city;
    public String state;
    public String postalCode;
    public String countryCode;
    public String phone;
    public String fax;
    public String email;
    public String taxId;
    public String npi;

    /**
     * Contructor to populate the Business Account for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     */
    public MVN_ConnectiveRxEnrollAccount(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.partnerId = fulfillmentRequest.MVN_Practice__c;
        this.name = fulfillmentRequest.MVN_Practice_Name__c;
        this.address1 = fulfillmentRequest.MVN_Practice_Address_Line_1__c;
        this.address2 = fulfillmentRequest.MVN_Practice_Address_Line_2__c;
        this.city = fulfillmentRequest.MVN_Practice_City__c;
        this.state = fulfillmentRequest.MVN_Practice_State__c;
        this.postalCode = fulfillmentRequest.MVN_Practice_Postal_Code__c;
        this.countryCode = Label.MVN_CRX_Enroll_Default_Country;
        this.phone = fulfillmentRequest.MVN_Practice_Phone__c;
        this.fax = fulfillmentRequest.MVN_Practice_Fax__c;
        this.email = fulfillmentRequest.MVN_Practice_Email__c;
        this.npi = fulfillmentRequest.MVN_Practice_NPI__c;
    }
}