/**
 * @author      Mavens
 * @description Sets Program Developer Name on Requests.
 */
public with sharing class PJN_CaseSetProgramDevNameHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handle before trigger context
     */
    public void handle() {
        Set<Id> parentCaseIds = new Set<Id>();
        for(Case currentCase : (List<Case>) trigger.new) {
            if(newOrUpdatedParentCase(currentCase)) {
                parentCaseIds.add(currentCase.ParentId);
            }
        }

        Map<Id, Case> parentCaseMap = queryParentCases(parentCaseIds);

        for(Case currentCase : (List<Case>) trigger.new) {
            if(newOrUpdatedParentCase(currentCase) && mapHasParentCaseData(parentCaseMap, currentCase.ParentId)) {
                Case parentCase = parentCaseMap.get(currentCase.ParentId);
                if (parentCase.PJN_Program__c != NULL && parentCase.PJN_Program__r.PJN_Program_DeveloperName__c != NULL) {
                    currentCase.PJN_Program_DeveloperName__c = parentCase.PJN_Program__r.PJN_Program_DeveloperName__c;
                } else {
                    currentCase.PJN_Program_DeveloperName__c = parentCase.PJN_Program_DeveloperName__c;
                }
            }
        }
    }

    private Boolean newOrUpdatedParentCase(Case newCase) {
        if (newCase.RecordTypeId == SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Request').getRecordTypeId()) {
            if (Trigger.isInsert) {
                return String.isNotBlank(newCase.ParentId);
            } else if (Trigger.isUpdate) {
                Case oldCase = (Case) Trigger.oldMap.get(newCase.Id);
                return String.isNotBlank(newCase.ParentId) && newCase.ParentId != oldCase.ParentId;
            }
        }

        return false;
    }

    private Boolean mapHasParentCaseData(Map<Id, Case> parentCaseMap, Id parentId) {
        if (parentCaseMap.containsKey(parentId)) {
            Case parentCase = parentCaseMap.get(parentId);
            return (parentCase.PJN_Program_DeveloperName__c != NULL || (parentCase.PJN_Program__c != NULL && parentCase.PJN_Program__r.PJN_Program_DeveloperName__c != NULL));
        }

        return false;
    }

    private Map<Id, Case> queryParentCases(Set<Id> parentCaseIds) {
        return new Map<Id, Case>([SELECT Id, PJN_Program_DeveloperName__c, PJN_Program__r.PJN_Program_DeveloperName__c FROM Case WHERE Id IN :parentCaseIds]);
    }
}