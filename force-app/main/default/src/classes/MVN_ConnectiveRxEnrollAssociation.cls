/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper Connective Rx Enrollment Assosiations
 */
public with sharing class MVN_ConnectiveRxEnrollAssociation {

    /**
     * JSON Parameters requesting into ConnectiveRx Assosiation
     */
    public String associationType;
    public String type;
    public Datetime signedDate;
    public Datetime expiryDate;
    public String age;
    public String name;
    public String description;

    private static final Set<String> HIPAA_CONSENT_TYPES = new Set<String> {
        'hipaa-authorization',
        'third-party-disclosure'
    };

    private static final Set<String> PROGRAM_CONSENT_TYPES = new Set<String> {
        'phone-communication',
        'email-communication',
        'mail-communication',
        'market-research'
    };

    /**
     * Contructor to populate the Assosiations for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     * @param associationType       Current assosiation type
     */
    public MVN_ConnectiveRxEnrollAssociation(PJN_Fulfillment_Request__c fulfillmentRequest, String associationType) {
        if (HIPAA_CONSENT_TYPES.contains(associationType.toLowerCase())) {
            setHipaaAuthorization(fulfillmentRequest, associationType);
        } else if (PROGRAM_CONSENT_TYPES.contains(associationType.toLowerCase())) {
            setProgramAuthorization(fulfillmentRequest, associationType);
        }
    }

    /**
     * Set HIPAA Authorization using fulfillment request to the assosiation type
     * @param fulfillmentRequest    Fulfillment Request record
     * @param associationType       Current assosiation type
     */
    private void setHipaaAuthorization(PJN_Fulfillment_Request__c fulfillmentRequest, String associationType) {
        this.associationType = Label.MVN_CRX_Enroll_Default_Association_Type.toLowerCase();
        this.type = associationType;
        this.signedDate = fulfillmentRequest.PJN_HIPPA_Consent_Date__c;
        this.expiryDate = fulfillmentRequest.PJN_HIPPA_Consent_Expiration_Date__c;
    }

    /**
     * Set Program Authorization using fulfillment request to the assosiation type
     * @param fulfillmentRequest    Fulfillment Request record
     * @param associationType       Current assosiation type
     */
    private void setProgramAuthorization(PJN_Fulfillment_Request__c fulfillmentRequest, String associationType) {
        this.associationType = Label.MVN_CRX_Enroll_Default_Association_Type.toLowerCase();
        this.type = associationType;
        this.signedDate = fulfillmentRequest.MVN_Program_Consent_Date__c;
        this.expiryDate = fulfillmentRequest.MVN_Program_Consent_Expiration_Date__c;
    }
}