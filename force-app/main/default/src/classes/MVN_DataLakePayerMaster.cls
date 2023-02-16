/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for Payer Master object
 */
public with sharing class MVN_DataLakePayerMaster {

    /**
     * Datalake Payer parameters
     */
    public String plan_id;
    public String plan;
    public String payerchannel_id;
    public String payerchannel;
    public String payer_id;
    public String payer;
    public String medical_channel;
    public String pharmacy_channel;
    public String channeldetail;
    public String pbm_id;
    public String medical_pbm_processor;
    public String pharmacy_pbm;
    public String pharmacy_pbm_relationship;
    public Date src_data_month;
    public Date px_data_month;
    public Date px_delivery_date;

    /**
     * Get Payer Record using the wrapper parameters obtained from callout
     * @return  `Account`
     */
    public Account getPayerRecord() {
        return new Account (
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesPayer').getRecordTypeId(),
            MVN_Payer_Channel_Precision_Id__c = this.payerchannel_id,
            MVN_Payer_Channel_Name__c = this.payerchannel,
            MVN_Precision_Id__c = this.payer_id,
            Name = this.payer,
            MVN_SRC_Data_Month__c = this.src_data_month,
            MVN_PX_Data_Month__c = this.px_data_month,
            MVN_PX_Delivery_Date__c = this.px_delivery_date
        );
    }

    /**
     * Get Payer Plan record using the wrapper parameters obtained from callout
     * @return  `MVN_Payer_Plan__c`
     */
    public MVN_Payer_Plan__c getPayerPlanRecord() {
        return new MVN_Payer_Plan__c (
            MVN_Precision_Id__c = this.plan_id,
            Name = this.plan,
            MVN_Payer_Precision_Id__c = this.payer_id,
            MVN_Payer__r = new Account(
                MVN_Precision_Id__c = this.payer_id
            ),
            MVN_Medical_Channel__c = this.medical_channel,
            MVN_Pharmacy_Channel__c = this.pharmacy_channel,
            MVN_Channel_Detail__c = this.channeldetail,
            MVN_PBM_Precision_Id__c = this.pbm_id,
            MVN_Medical_PBM_Processor__c = this.medical_pbm_processor,
            MVN_Pharmacy_PBM__c = this.pharmacy_pbm,
            MVN_Pharmacy_PBM_Relationship__c = this.pharmacy_pbm_relationship,
            MVN_SRC_Data_Month__c = this.src_data_month,
            MVN_PX_Date_Month__c = this.px_data_month,
            MVN_PX_Delivery_Date__c = this.px_delivery_date
        );
    }
}