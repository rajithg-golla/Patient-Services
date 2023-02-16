/**
 * @author Mavens
 * @date Nov 2019
 * @description Controller for the screen "Select Care Plan"
 *    - Get all care plans associated to a patient
 *    - Set care plan to activity case
 * @group AccountSearch
 */
public without sharing class PJN_AccountSearchCarePlanSelectorCtrl {
    /**
     * global describe
     */
    private static Map<String,Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    /**
     * Get list of care plans for patient
     * @param  accountId patient id
     * @param  caseId    activity case id
     * @return PJN_CarePlanSelectorWrapper
     */
    @AuraEnabled
    public static PJN_CarePlanSelectorWrapper getCarePlans(String accountId, String caseId) {
        PJN_CarePlanSelectorWrapper carePlanWrapper = new PJN_CarePlanSelectorWrapper();
        carePlanWrapper.fieldList = PJN_Utilities.getFields('Case', 'PJN_Care_Plan_Selector_Screen');
        carePlanWrapper.fieldLabels = getFieldLabels(carePlanWrapper.fieldList);
        List<Case> carePlanList = getCarePlanList(accountId, caseId, carePlanWrapper.fieldList);
        carePlanWrapper.carePlanWrapperList = getCarePlanWrapperList(carePlanList);
        return carePlanWrapper;
    }

    /**
     * Get field labels for fields on the field set
     * @param  fieldList List of fields
     * @return List<String>
     */
    private static List<String> getFieldLabels(List<String> fieldList) {
        List<String> fieldLabels = new List<String>();
        Map<String,Schema.SObjectField> caseAllFieldDescribe = globalDescribe.get('Case').getDescribe().fields.getMap();
        for (String field : fieldList) {
            fieldLabels.add(caseAllFieldDescribe.get(field).getDescribe().getLabel());
        }
        return fieldLabels;
    }

    /**
     * Retrieve care plan records for a patient
     * @param  fieldList list of fields to retrieve
     * @return List<Case>
     */
    private static List<Case> getCarePlanList(Id accountId, Id caseId, List<String> fieldList) {
        Set<String> fields = new Set<String>{'Id', 'PJN_Program_DeveloperName__c', 'Subject'};
        fields.addAll(fieldList);
        String queryString = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(fields), ','))
                + ' FROM Case '
                + 'WHERE RecordType.DeveloperName = \'CarePlan\' '
                + 'AND AccountId = :accountId '
                + 'AND Id != :caseId';
        return (List<Case>)Database.query(queryString);
    }

    /**
     * Get care plan wrapper list with boolean access to that record
     * @param  carePlanList list of care plans
     * @return PJN_CarePlanSelectorWrapper.PJN_CarePlanRecordWrapper
     */
    private static List<PJN_CarePlanSelectorWrapper.PJN_CarePlanRecordWrapper> getCarePlanWrapperList(List<Case> carePlanList) {
        List<PJN_CarePlanSelectorWrapper.PJN_CarePlanRecordWrapper> carePlanWrapperList = new List<PJN_CarePlanSelectorWrapper.PJN_CarePlanRecordWrapper>();
        List<UserRecordAccess> userRecordAccessList = [
            SELECT
                RecordId, HasReadAccess
            FROM
                UserRecordAccess
            WHERE
                UserId = :UserInfo.getUserId()
            AND
                RecordId In :getCarePlanIds(carePlanList)
        ];
        Map<Id, Boolean> caseAccessById = new Map<Id, Boolean>();
        for (UserRecordAccess userAccess : userRecordAccessList) {
            caseAccessById.put(userAccess.RecordId, userAccess.HasReadAccess);
        }

        for (Case carePlan : carePlanList) {
            carePlanWrapperList.add(new PJN_CarePlanSelectorWrapper.PJN_CarePlanRecordWrapper(carePlan, caseAccessById.get(carePlan.Id)));
        }
        return carePlanWrapperList;
    }

    /**
     * Get Set of Care Plan Ids
     * @param  carePlanList care plan list
     * @return Set<Id>
     */
    private static Set<Id> getCarePlanIds(List<Case> carePlanList) {
        Set<Id> carePlanIds = new Set<Id>();
        for (Case carePlan : carePlanList) {
            carePlanIds.add(carePlan.Id);
        }
        return carePlanIds;
    }

    /**
     * Set care plan for current activity case
     * @param  caseId activity case id
     * @param  planId care plan id
     * @return Case
     */
    @AuraEnabled
    public static Case setPatientCarePlan(String caseId, String planId) {
        boolean successful = true;

        Case mainCase = new Case(
            Id = caseId,
            ParentId = planId
        );

        try {
            update mainCase;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unable to set patient care plan on case: ' + e.getMessage());
            return null;
        }

        return getCase(caseId);
    }

    /**
     * Retrieve case record
     * @param  caseId case id
     * @return Case
     */
    private static Case getCase(Id caseId) {
        if (caseId == null) {
            return null;
        }
        return [
            SELECT
                Id,
                AccountId,
                Account.Name,
                PJN_Caregiver__c,
                PJN_Caregiver__r.Name,
                PJN_Physician__c,
                PJN_Physician__r.Name,
                PJN_Staff__c,
                PJN_Staff__r.Name,
                ParentId,
                RecordType.DeveloperName,
                PJN_Enrollment_Address__c
            FROM
                Case
            WHERE
                Id = :caseId
        ];
    }

}