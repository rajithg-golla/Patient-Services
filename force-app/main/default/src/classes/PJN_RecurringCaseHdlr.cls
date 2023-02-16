/**
 * @author      Mavens
 * @date        04/2021
 * @description Case handler to clone recurring cases on close
 * @group       Case
 */
public with sharing class PJN_RecurringCaseHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    private static final String REPEAT = System.label.PJN_Recurring_Case_Repeats;
    private static final String CASE_STATUS = System.label.PJN_Case_Quick_Open_Status;
    private static final String CASE_ORIGIN = System.label.PJN_Recurring_Case_Origin;

    /**
     * Trigger handler to clone cases that were configured to repeat
     */
    public void handle() {
        Set<Id> recurringCaseIds = this.filterRecurringCases();

        List<Case> clonedCases = new List<Case>();
        for (Case currentCase : this.getRecurringCases(recurringCaseIds)) {
            Case clonedCase = currentCase.clone();
            clonedCase.Status = CASE_STATUS;
            clonedCase.Origin = CASE_ORIGIN;
            clonedCase.HealthCloudGA__DueDate__c = currentCase.PJN_Next_Activity__c;
            clonedCases.add(clonedCase);
        }
        insert clonedCases;
    }

    /**
     * @description returns id set of cases configured to repeat
     *
     * @return `Set<Id>`
     */
    private Set<Id> filterRecurringCases() {
        Set<Id> recurringCaseIds = new Set<Id>();
        for (Case currentCase : (List<Case>) Trigger.new) {
            if (currentCase.PJN_Repeat__c == REPEAT && caseWasClosed(currentCase)) {
                recurringCaseIds.add(currentCase.Id);
            }
        }
        return recurringCaseIds;
    }


    /**
     * @description checks if case was closed
     *
     * @return `Boolean`
     */
    private Boolean caseWasClosed(Case currentCase) {
        if (!currentCase.IsClosed) {
            return false;
        }
        if (Trigger.isInsert) {
            return true;
        }

        Case oldCase = (Case) Trigger.oldMap.get(currentCase.Id);
        return oldCase.isClosed != currentCase.isClosed;
    }

    /**
     * @description queries list of cases to be cloned
     * @param caseIds
     * @return  `List<Case>`
     */
    private List<Case> getRecurringCases(Set<Id> caseIds) {
        return Database.query('SELECT ' + this.getRecurringCaseFieldsString() + ' FROM Case WHERE Id IN :caseIds');
    }

    /**
     * @description returns the Recurring Case Clone field set fields as a comma-separated string
     * @return  `String`
     */
    private String getRecurringCaseFieldsString() {
        List<Schema.FieldSetMember> fieldSetMembers = Schema.SObjectType.Case.fieldSets.PJN_Recurring_Case_Clone_Fields.getFields();

        Set<String> recurringCaseFields = new Set<String>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            recurringCaseFields.add(fsm.fieldpath);
        }

        return String.join(new List<String>(recurringCaseFields), ', ');
    }
}