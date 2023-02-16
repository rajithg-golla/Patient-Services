/**
 * @author Mavens
 * @date Jan 2019
 * @description Handler that calls the class in charge of creating Case Team Roles against the Care Plan when:
 *  ON UPDATE:
 *    - ParentId is updated in the activity/child case
 *    - Any of the fields Patient/Caregiver/Physician/Staff changes in the child request/activity case
 *    - Any of the fields Patient/Caregiver/Physician/Staff changes in the care plan
 *  ON INSERT:
 *    - Care Plan inserted with any of the fields Patient/Caregiver/Physician/Staff filled
 */
public without sharing class PJN_CaseTeamMemberHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    /**
    * @description Map of case fields to monitor to the roles they control for case team
    */
    private static Map<String, PJN_Case_Field_Configuration__mdt> caseFieldToConfigMap {
        get {
            if (caseFieldToConfigMap == null) {
                List<PJN_Case_Field_Configuration__mdt> configuredRecords = PJN_CaseFieldConfigurations.all;

                caseFieldToConfigMap = new Map<String, PJN_Case_Field_Configuration__mdt>();
                for (PJN_Case_Field_Configuration__mdt config : configuredRecords) {
                    caseFieldToConfigMap.put(config.PJN_Case_Field_API_Name__c, config);
                }
            }
            return caseFieldToConfigMap;
        }
        private set;
    }

    /**
     * Handle the trigger call
     */
    public void handle() {
        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Map<Id, Case> casesToMoveTeamMembers = new Map<Id, Case>{};
        List<Case> carePlansToUpdateTeamMembers = new List<Case>();
        for (Case currentCase : (List<Case>)Trigger.new) {
            if (currentCase.RecordTypeId != carePlanRecordTypeId && this.isParentIdUpdated(currentCase.Id) ||
                (currentCase.parentId != null && this.isAnyCareTeamFieldsUpdated(currentCase.Id))) {

                casesToMoveTeamMembers.put(currentCase.Id, currentCase);
            } else if (currentCase.RecordTypeId == carePlanRecordTypeId && this.isAnyCareTeamFieldsUpdated(currentCase.Id)){
                carePlansToUpdateTeamMembers.add(currentCase);
            }
        }
        if (!casesToMoveTeamMembers.isEmpty()) {
            PJN_CaseTeamMemberManager.createTeamMembersAndContactRelationships(casesToMoveTeamMembers.values());
        }
        if (!carePlansToUpdateTeamMembers.isEmpty()) {
            PJN_CaseTeamMemberManager.createTeamMembersAndContactRelationshipsForCarePlanUpdate(carePlansToUpdateTeamMembers);
        }
    }

    /**
     * Checks if the ParentId field has been updated
     * @param  caseId case id
     * @returns        true if the ParentId has changed and it is not null
     */
    private Boolean isParentIdUpdated(Id caseId) {
        if (Trigger.isUpdate) {
            Case oldCase = (Case) Trigger.oldMap.get(caseId);
            Case newCase = (Case) Trigger.newMap.get(caseId);
            if (oldCase.parentId != newCase.parentId && newCase.parentId != null) {
                return true;
            }
        }
        return false;
    }

    /**
     * Checks if any of the fields that participates in the creation of the team roles has changed
     * @param  caseId case id
     * @returns        true if any of the fields has changed
     */
    private Boolean isAnyCareTeamFieldsUpdated(Id caseId) {
        Case newCase = (Case) Trigger.newMap.get(caseId);
        if (Trigger.isInsert) {
            for (String field : caseFieldToConfigMap.keySet()) {
                if (newCase.get(field) != null) {
                    return true;
                }
            }
        } else if (Trigger.isUpdate) {
            Case oldCase = (Case) Trigger.oldMap.get(caseId);
            for (String field : caseFieldToConfigMap.keySet()) {
                if (oldCase.get(field) != newCase.get(field) && newCase.get(field) != null) {
                    return true;
                }
            }
        }
        return false;
    }
}