/*
 * @description Controller for the Medial History Lightning Web Components
 * @author      Mavens
 * @Created     October 2019
 */
public with sharing class PJN_MedicalHistoryCtrl {

    /*
     * @description given a care plan id and med history record type id, return all med history
     *              records for the care plan with the given record type
     * @param       Id - carePlanId
     * @param       Id - medical history record type Id
     * @param       Boolean - shows all related to patient
     * @returns     List<PJN_Medical_History__c
     */
    @AuraEnabled (cacheable=true)
    public static List<PJN_Medical_History__c> getMedicalHistory(Id carePlanId, String recordTypeId, Boolean showAllForCurrentPatient) {
        Set<String> fields = new Set<String> {
            'Id',
            'Name',
            'PJN_Details__c',
            'PJN_Dates_Formula__c'
        };

        String whereStatement = getMedicalHistoryWhereStatement(carePlanId, recordTypeId, showAllForCurrentPatient);

        String query = String.format (
            'SELECT {0} FROM {1} WHERE {2}',
            new List<String> {
                String.join(new List<String>(fields), ','),
                PJN_Medical_History__c.sObjectType.getDescribe().getName(),
                whereStatement
            }
        );

        return Database.query(query);
    }

    /**
     * @description Get Medical History where statement depending on showAllForCurrentPatient parameter
     * @param       Id - carePlanId
     * @param       Id - medical history record type Id
     * @param       Boolean - only shows related to current patient
     * @returns String - where statement
     */
    private static String getMedicalHistoryWhereStatement(Id carePlanId, String recordTypeId, Boolean showAllForCurrentPatient) {
        String carePlanOrPatientFilter = 'PJN_Care_Plan__c = :carePlanId';

        if (showAllForCurrentPatient) {
            Id patientId = getCurrentPatient(carePlanId);
            carePlanOrPatientFilter = 'PJN_Patient__c = \'' + patientId + '\'';
        }

        return carePlanOrPatientFilter + ' AND RecordTypeId = :recordTypeId';
    }

    /**
     * @description Get current patient Id from CarePlan
     * @param       Id - carePlanId
     * @returns     Patient Id
     */
    private static Id getCurrentPatient(Id carePlanId) {
        return [
            SELECT
                AccountId
            FROM
                Case
            WHERE
                Id = :carePlanId
        ].AccountId;
    }

    /*
     * @description returns the record type id for the metric record type on medical history.
     *              This is used by the medical history lighting web componts as the standard calls
     *              for the objects to not return the record type ids for some reason
     * @returns     Id - record type id
     */
    @AuraEnabled (cacheable=true)
    public static Id getMetricRecTypeId(){
        return SObjectType.PJN_Medical_History__c
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Metric')
            .getRecordTypeId();
    }
}