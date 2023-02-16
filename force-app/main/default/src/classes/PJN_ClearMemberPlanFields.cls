/**
 * @author      Mavens
 * @description If a member plan is updated to a different coverage order, the lookup field in the
 *              Care Plan needs to be reset.
 * @group       CarePlan Fields Mapping
 */
public with sharing class PJN_ClearMemberPlanFields implements PJN_TriggerDispatcher.HandlerInterface  {


    public void handle() {
        for (Case currentCase : (List<Case>)Trigger.new) {
            Case oldCase = (Case) Trigger.oldMap.get(currentCase.Id);
            handlePrimaryMemberPlanChange(currentCase, oldCase);
            handleSecondaryMemberPlanChange(currentCase, oldCase);
            handleTertiaryMemberPlanChange(currentCase, oldCase);
        }
    }

    /**
     * @description Check if Primary Member Plan lookup field has changed, if so, clear that value
     *              from the rest of Member Plan lookup fields
     * @param  currentCase case being updated with the new values
     * @param  oldCase     case being updated with the old values
     */
    private void handlePrimaryMemberPlanChange(Case currentCase, Case oldCase) {
        if (currentCase.PJN_Primary_Member_Plan__c != oldCase.PJN_Primary_Member_Plan__c &&
            currentCase.PJN_Primary_Member_Plan__c != null) {
            if (currentCase.PJN_Primary_Member_Plan__c == oldCase.PJN_Secondary_Member_Plan__c) {
                currentcase.PJN_Secondary_Member_Plan__c = null;
            }
            if (currentCase.PJN_Primary_Member_Plan__c == oldCase.PJN_Tertiary_Member_Plan__c) {
                currentcase.PJN_Tertiary_Member_Plan__c = null;
            }
        }
    }

    /**
     * @description Check if Secondary Member Plan lookup field has changed, if so, clear that value
     *              from the rest of Member Plan lookup fields
     * @param  currentCase case being updated with the new values
     * @param  oldCase     case being updated with the old values
     */
    private void handleSecondaryMemberPlanChange(Case currentCase, Case oldCase) {
        if (currentCase.PJN_Secondary_Member_Plan__c != oldCase.PJN_Secondary_Member_Plan__c &&
            currentCase.PJN_Secondary_Member_Plan__c != null) {
            if (currentCase.PJN_Secondary_Member_Plan__c == oldCase.PJN_Primary_Member_Plan__c) {
                currentcase.PJN_Primary_Member_Plan__c = null;
            }
            if (currentCase.PJN_Secondary_Member_Plan__c == oldCase.PJN_Tertiary_Member_Plan__c) {
                currentcase.PJN_Tertiary_Member_Plan__c = null;
            }
        }
    }

    /**
     * @description Check if Tertiary Member Plan lookup field has changed, if so, clear that value
     *              from the rest of Member Plan lookup fields
     * @param  currentCase case being updated with the new values
     * @param  oldCase     case being updated with the old values
     */
    private void handleTertiaryMemberPlanChange(Case currentCase, Case oldCase) {
        if (currentCase.PJN_Tertiary_Member_Plan__c != oldCase.PJN_Tertiary_Member_Plan__c &&
            currentCase.PJN_Tertiary_Member_Plan__c != null) {
            if (currentCase.PJN_Tertiary_Member_Plan__c == oldCase.PJN_Primary_Member_Plan__c) {
                currentcase.PJN_Primary_Member_Plan__c = null;
            }
            if (currentCase.PJN_Tertiary_Member_Plan__c == oldCase.PJN_Secondary_Member_Plan__c) {
                currentcase.PJN_Secondary_Member_Plan__c = null;
            }
        }
    }
}