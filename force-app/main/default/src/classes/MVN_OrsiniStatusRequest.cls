/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Status Request
 */
public with sharing class MVN_OrsiniStatusRequest {

    /**
     * JSON parameters from Orsini Request
     */
    public String pharmacy_patient_id;
    public String hub_patient_id;
    public String status;
    public String substatus;
    public String substatus_description;
    public Datetime status_date;

    /**
     * Get Event SFDC record using Orsini Status parameters
     * @param carePlan  CarePlan record to be related to
     * @return  `PJN_Event__c`
     */
    public PJN_Event__c getEvent(Case carePlan) {
        return new PJN_Event__c (
            RecordTypeId = Schema.SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('MVN_Pharmacy_Status_Update').getRecordTypeId(),
            PJN_Case__c = carePlan.Id,
            PJN_Patient__c = carePlan.AccountId,
            PJN_Program_DeveloperName__c = carePlan.PJN_Program_DeveloperName__c,
            PJN_SP_Patient_ID__c = this.pharmacy_patient_id,
            PJN_Status__c = this.status,
            PJN_Sub_Status__c = this.substatus,
            PJN_Status_Date__c = this.status_date != null ? this.status_date.date() : null,
            MVN_SubStatus_Description__c = this.substatus_description
        );
    }
}