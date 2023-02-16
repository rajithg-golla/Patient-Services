/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for Result enrollment
 */
public with sharing class MVN_ConnectiveRxEnrollResult {

    /**
     * JSON Parameters from ConnectiveRx Result
     */
    public String id;
    public String brand;
    public String brandId;
    public String programId;
    public List<String> benefitTypes;
    public Boolean isActive;
    public String status;
    public Boolean isReenrollment;
    public MVN_ConnectiveRxEnrollPersonAccount patient;
    public MVN_ConnectiveRxEnrollPersonAccount prescribingPhysician;
    public MVN_ConnectiveRxEnrollAccount referralPractice;
    public List<MVN_ConnectiveRxEnrollOutcome> outcomes;
    public List<MVN_ConnectiveRxEnrollAssociation> associations;
    public List<MVN_ConnectiveRxEnrollMetadata> metaInfo;

    /**
     * Get Assistance Program record updated with the ConnectiveRx Result
     * @param assistanceProgram     Assistance Program record
     * @return  `PJN_Assistance_Program__c`
     */
    public PJN_Assistance_Program__c getAssistanceProgram(PJN_Assistance_Program__c assistanceProgram) {
        assistanceProgram.MVN_Copay_Enrollment_Id__c = this.id;
        assistanceProgram.MVN_Copay_Status__c = this.status;
        assistanceProgram.MVN_Copay_Is_Reenrollment__c = this.isReenrollment;
        if (this.patient != null) {
            assistanceProgram.MVN_Copay_Patient_Id__c = this.patient.id;
        }
        if (this.patient != null && this.patient.caregiver != null) {
            assistanceProgram.MVN_Copay_Caregiver_Id__c = this.patient.caregiver.id;
        }
        if (this.patient != null && this.patient.membership != null) {
            assistanceProgram.MVN_Copay_Group_Number__c = this.patient.membership.groupNumber;
            assistanceProgram.MVN_Copay_Member_Id__c = this.patient.membership.memberId;
            assistanceProgram.MVN_Copay_BIN__c = this.patient.membership.bin;
            assistanceProgram.MVN_Copay_PCN__c = this.patient.membership.pcn;
            assistanceProgram.MVN_Copay_Is_Activated__c = this.patient.membership.isActivated;
            assistanceProgram.MVN_Copay_Issued_Date__c = this.patient.membership.issuedDate;
            assistanceProgram.MVN_Copay_Effective_Date__c = this.patient.membership.effectiveDate;
            assistanceProgram.MVN_Copay_Activated_Date__c = this.patient.membership.activatedDate;
            assistanceProgram.MVN_Copay_Expiration_Date__c = this.patient.membership.expirationDate;
            assistanceProgram.MVN_Copay_Deactivated_Date__c = this.patient.membership.deactivatedDate;
            assistanceProgram.MVN_Copay_Program_Cap__c = this.patient.membership.programCap;
            assistanceProgram.MVN_Copay_Total_Uses__c = this.patient.membership.totalUses;
            assistanceProgram.MVN_Copay_Usage_Period__c = this.patient.membership.usagePeriodValue;
            assistanceProgram.MVN_Copay_Usage_Period_Unit__c = this.patient.membership.usagePeriodUnit;
            assistanceProgram.MVN_Copay_Is_Active__c = this.patient.membership.isActive;
        }
        if (this.outcomes != null && !this.outcomes.isEmpty()) {
            assistanceProgram.MVN_Copay_Eligibility_Check_Type__c = this.outcomes[0].type;
            assistanceProgram.MVN_Copay_Enrollment_Success__c = this.outcomes[0].success;
            assistanceProgram.MVN_Copay_Enrollment_Result_Details__c = this.outcomes[0].message;
        }
        return assistanceProgram;
    }

    /**
     * Get Fulfillment Request record updated with the ConnectiveRx Result
     * @param fulfillment   Fulfillment Request record
     * @return  `PJN_Fulfillment_Request__c`
     */
    public PJN_Fulfillment_Request__c getFulfillmentUpdated(PJN_Fulfillment_Request__c fulfillment) {
        Map<String, Schema.RecordTypeInfo> fulfillmentRecordTypes = Schema.SObjectType.PJN_Fulfillment_Request__c.getRecordTypeInfosByDeveloperName();
        Boolean hasCopayRecordType = fulfillment.RecordTypeId == fulfillmentRecordTypes.get('MVN_Copay_Enrollment').getRecordTypeId()
            && fulfillmentRecordTypes.containsKey('MVN_Copay_Submitted');
        PJN_Fulfillment_Request__c fulfillmentToUpdate = new PJN_Fulfillment_Request__c(
            Id = fulfillment.Id,
            MVN_Copay_Enrollment_Id__c = this.id,
            MVN_Copay_Status__c = this.status,
            MVN_Copay_Is_Reenrollment__c = this.isReenrollment,
            PJN_Fulfillment_Request_Status__c = 'Processed',
            RecordTypeId = hasCopayRecordType ? fulfillmentRecordTypes.get('MVN_Copay_Submitted').getRecordTypeId() : fulfillment.RecordTypeId
        );
        if (this.patient != null) {
            fulfillmentToUpdate.MVN_Copay_Patient_Id__c = this.patient.id;
        }
        if (this.patient != null && this.patient.caregiver != null) {
            fulfillmentToUpdate.MVN_Copay_Caregiver_Id__c = this.patient.caregiver.id;
        }
        if (this.patient != null && this.patient.membership != null) {
            fulfillmentToUpdate.MVN_Copay_Group_Number__c = this.patient.membership.groupNumber;
            fulfillmentToUpdate.MVN_Copay_Member_Id__c = this.patient.membership.memberId;
            fulfillmentToUpdate.MVN_Copay_BIN__c = this.patient.membership.bin;
            fulfillmentToUpdate.MVN_Copay_PCN__c = this.patient.membership.pcn;
            fulfillmentToUpdate.MVN_Copay_Is_Activated__c = this.patient.membership.isActivated;
            fulfillmentToUpdate.MVN_Copay_Issued_Date__c = this.patient.membership.issuedDate;
            fulfillmentToUpdate.MVN_Copay_Effective_Date__c = this.patient.membership.effectiveDate;
            fulfillmentToUpdate.MVN_Copay_Activated_Date__c = this.patient.membership.activatedDate;
            fulfillmentToUpdate.MVN_Copay_Expiration_Date__c = this.patient.membership.expirationDate;
            fulfillmentToUpdate.MVN_Copay_Deactivated_Date__c = this.patient.membership.deactivatedDate;
            fulfillmentToUpdate.MVN_Copay_Program_Cap__c = this.patient.membership.programCap;
            fulfillmentToUpdate.MVN_Copay_Total_Uses__c = this.patient.membership.totalUses;
            fulfillmentToUpdate.MVN_Copay_Usage_Period__c = this.patient.membership.usagePeriodValue;
            fulfillmentToUpdate.MVN_Copay_Usage_Period_Unit__c = this.patient.membership.usagePeriodUnit;
            fulfillmentToUpdate.MVN_Copay_Is_Active__c = this.patient.membership.isActive;
        }
        if (this.outcomes != null && !this.outcomes.isEmpty()) {
            fulfillmentToUpdate.MVN_Copay_Eligibility_Check_Type__c = this.outcomes[0].type;
            fulfillmentToUpdate.MVN_Copay_Enrollment_Success__c = this.outcomes[0].success;
            fulfillmentToUpdate.MVN_Copay_Enrollment_Result_Details__c = this.outcomes[0].message;
        }
        return fulfillmentToUpdate;
    }
}