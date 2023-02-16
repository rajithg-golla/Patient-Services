/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for ConnectiveRx Enrollment
 */
public with sharing class MVN_ConnectiveRxEnrollmentWrapper {

    /**
     * JSON Parameters requesting into ConnectiveRx Enrollment
     */
    public String channel;
    public String brand;
    public String brandId;
    public String programId;
    public MVN_ConnectiveRxEnrollPersonAccount patient;
    public MVN_ConnectiveRxEnrollPersonAccount prescribingPhysician;
    public MVN_ConnectiveRxEnrollAccount referralPractice;
    public List<MVN_ConnectiveRxEnrollAssociation> associations;
    public List<String> benefitTypes;

    /**
     * Constructor to populate the Enrollment for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request
     */
    public MVN_ConnectiveRxEnrollmentWrapper(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.channel = Label.MVN_CRX_Enroll_Channel;
        this.brand = fulfillmentRequest.MVN_Brand__c;
        this.patient = new MVN_ConnectiveRxEnrollPersonAccount(fulfillmentRequest, 'patient');
        this.prescribingPhysician = new MVN_ConnectiveRxEnrollPersonAccount(fulfillmentRequest, 'physician');
        this.referralPractice = new MVN_ConnectiveRxEnrollAccount(fulfillmentRequest);
        this.associations = setAssociations(fulfillmentRequest);
        this.benefitTypes = new List<String>{Label.MVN_CRX_Enroll_Default_Benefit_Type};
    }

    /**
     * Set Patient Enrollment Associations (Consents)
     * @param fulfillmentRequest    Fulfillment Request record
     * @return  `List<MVN_ConnectiveRxEnrollAssociation>`
     */
    private static List<MVN_ConnectiveRxEnrollAssociation> setAssociations(PJN_Fulfillment_Request__c fulfillmentRequest) {
        List<MVN_ConnectiveRxEnrollAssociation> associations = new List<MVN_ConnectiveRxEnrollAssociation>();
        MVN_ConnectiveRxEnrollAssociation hipaaAuth = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'hipaa-authorization');
        if (hipaaAuth.signedDate != null) {
            associations.add(hipaaAuth);
        }
        MVN_ConnectiveRxEnrollAssociation thirdParty = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'third-party-disclosure');
        if (thirdParty.signedDate != null) {
            associations.add(thirdParty);
        }
        MVN_ConnectiveRxEnrollAssociation phoneAuth = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'phone-communication');
        if (phoneAuth.signedDate != null) {
            associations.add(phoneAuth);
        }
        MVN_ConnectiveRxEnrollAssociation emailAuth = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'email-communication');
        if (emailAuth.signedDate != null) {
            associations.add(emailAuth);
        }
        MVN_ConnectiveRxEnrollAssociation mailAuth = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'mail-communication');
        if (mailAuth.signedDate != null) {
            associations.add(mailAuth);
        }
        MVN_ConnectiveRxEnrollAssociation marketAuth = new MVN_ConnectiveRxEnrollAssociation(fulfillmentRequest, 'market-research');
        if (marketAuth.signedDate != null) {
            associations.add(marketAuth);
        }
        return associations;
    }
}