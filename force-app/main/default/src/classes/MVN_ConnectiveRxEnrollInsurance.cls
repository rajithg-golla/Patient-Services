/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the Insurance in the Enrollment Request
 */
public with sharing class MVN_ConnectiveRxEnrollInsurance {

    /**
     * JSON Parameters requesting into ConnectiveRx Insurance
     */
    public String groupNumber;
    public String memberId;
    public String payerName;
    public String insuranceTypeCode;
    public Date effectiveDate;
    public String payerPlanName;
    public String bin;
    public String pcn;
    public Integer ordinal;

    /**
     * Primary Insurance Type Code mapping from SFDC to ConnectiveRx
     */
    private static final Map<String, String> PRIMARY_INSURANCE_TYPE_CODE_MAPPING = new Map<String, String> {
        Label.MVN_CRX_Enroll_Insurance_Medical_Type => Label.MVN_CRX_Enroll_Insurance_Primary_Medical,
        Label.MVN_CRX_Enroll_Insurance_Pharmacy_Type => Label.MVN_CRX_Enroll_Ins_Primary_Prescription
	};

    /**
     * Secondary Insurance Type Code mapping from SFDC to ConnectiveRx
     */
    private static final Map<String, String> SECONDARY_INSURANCE_TYPE_CODE_MAPPING = new Map<String, String> {
        Label.MVN_CRX_Enroll_Insurance_Medical_Type => Label.MVN_CRX_Enroll_Insurance_Secondary_Medical,
        Label.MVN_CRX_Enroll_Insurance_Pharmacy_Type => Label.MVN_CRX_Enroll_Ins_Secondary_Prescription
    };

    /**
     * Constructor to populate the Insurance for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request
     * @param isPrimary             Defines either primary or secundary insurance
     */
    public MVN_ConnectiveRxEnrollInsurance(PJN_Fulfillment_Request__c fulfillmentRequest, Boolean isPrimary) {
        if (isPrimary) {
            setPrimaryInsurance(fulfillmentRequest);
        } else {
            setSecondaryInsurance(fulfillmentRequest);
        }
    }

    /**
     * Set Primary Insurance record using fulfillment request record
     * @param fulfillmentRequest    Fulfillment Request record
     */
    private void setPrimaryInsurance(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.groupNumber = fulfillmentRequest.PJN_Primary_Group_Number__c;
        this.memberId = fulfillmentRequest.PJN_Primary_Insurance_ID__c;
        this.payerName = fulfillmentRequest.PJN_Primary_Payer_Name__c;
        this.insuranceTypeCode = PRIMARY_INSURANCE_TYPE_CODE_MAPPING.containsKey(fulfillmentRequest.MVN_Primary_Coverage_Type__c) ?
            PRIMARY_INSURANCE_TYPE_CODE_MAPPING.get(fulfillmentRequest.MVN_Primary_Coverage_Type__c) :
            null;
        this.effectiveDate = fulfillmentRequest.MVN_Primary_Effective_Date__c;
        this.payerPlanName = fulfillmentRequest.PJN_Primary_Plan_Name__c;
        this.bin = fulfillmentRequest.PJN_Primary_BIN__c;
        this.pcn = fulfillmentRequest.PJN_Primary_PCN__c;
    }

    /**
     * Set Secondary Insurance record using fulfillment request record
     * @param fulfillmentRequest    Fulfillment Request record
     */
    private void setSecondaryInsurance(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.groupNumber = fulfillmentRequest.PJN_Secondary_Group_Number__c;
        this.memberId = fulfillmentRequest.PJN_Secondary_Insurance_ID__c;
        this.payerName = fulfillmentRequest.PJN_Secondary_Payer_Name__c;
        this.insuranceTypeCode = SECONDARY_INSURANCE_TYPE_CODE_MAPPING.containsKey(fulfillmentRequest.MVN_Secondary_Coverage_Type__c) ?
            SECONDARY_INSURANCE_TYPE_CODE_MAPPING.get(fulfillmentRequest.MVN_Secondary_Coverage_Type__c) :
            null;
        this.effectiveDate = fulfillmentRequest.MVN_Secondary_Effective_Date__c;
        this.payerPlanName = fulfillmentRequest.PJN_Secondary_Plan_Name__c;
        this.bin = fulfillmentRequest.PJN_Secondary_BIN__c;
        this.pcn = fulfillmentRequest.PJN_Secondary_PCN__c;
    }
}