/**
 * @author      Mavens
 * @group       Fulfillment
 * @description class to query fulfillment request creation metadata
 */
public with sharing class PJN_FulfillmentRequestCreationQuery {
    /**
     * query by program developer name and by record type developer name
     * @param   String        programDeveloperName
     * @param   String        recordTypeDeveloperName
     * @returns  List<PJN_Fulfillment_Request_Creation__mdt>
     */
    public List<PJN_Fulfillment_Request_Creation__mdt> queryByProgramDeveloperNameAndRecordTypeDeveloperName(String programDeveloperName, String recordTypeDeveloperName) {
        return [
            SELECT
                Id,
                PJN_Care_Plan_Source_Field_API_Name__c,
                PJN_Request_Target_Field_API_Name__c,
                PJN_Mapping_Object_Type_Name__c,
                PJN_Record_Type_Developer_Name__c
            FROM
                PJN_Fulfillment_Request_Creation__mdt
            WHERE
                PJN_Program__r.DeveloperName = :programDeveloperName
            AND
                PJN_Record_Type_Developer_Name__c = :recordTypeDeveloperName
        ];
    }
}