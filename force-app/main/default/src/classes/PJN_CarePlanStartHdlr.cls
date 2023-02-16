/**
 * @author      Mavens
 * @group       CarePlanHdlr
 * @description Event start events for cases that are inserted or updated with PJN_Program_DeveloperName__c
 *              and the start flag set to true. Optionally start the program at a specific problem

 */
public with sharing class PJN_CarePlanStartHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    private final String NOT_CARE_PLAN_ERROR = 'Only care plans can be started.';
    private final String MISSING_PROGRAM_ERROR = 'A Program Developer Name (PJN_Program_DeveloperName__c) is required to start a care plan.';
    private final String PUBLISHING_ERROR = 'Error publishing care plan start events: ';

    @TestVisible
    private static Set<Id> newlyPendingIds = new Set<Id>();

    public void handle() {
        if (Trigger.isBefore) {
            evalutateCasesForCarePlansToStart();
        } else {
            publishStartEvents();
        }
    }

    private void evalutateCasesForCarePlansToStart() {
        Id carePlanRecTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();

        for (Case currentCase : (List<Case>) Trigger.new) {
            if (currentCase.PJN_Care_Plan_Start_Status__c != 'PJN_Initiate') {
                continue;
            }

            // Only care plans can be Started
            if (currentCase.RecordTypeId != carePlanRecTypeId) {
                currentCase.addError(NOT_CARE_PLAN_ERROR);
                continue;
            }

            // To start a care plan it needs a developer name
            if (String.isBlank(currentCase.PJN_Program_DeveloperName__c)) {
                currentCase.addError(MISSING_PROGRAM_ERROR);
                continue;
            }

            // By immediately changing to pending there is no need to check if the value is insert or update and changed
            // since it is automatically changed when the value is initiate
            // add to newlyPendingIds to know the ids that need events emitted for them
            currentCase.PJN_Care_Plan_Start_Status__c = 'PJN_Pending';
            if (Trigger.isUpdate) {
                newlyPendingIds.add(currentCase.Id);
            }
        }
    }

    private void publishStartEvents() {

        List<PJN_Program_Event__e> programStartEvents = new List<PJN_Program_Event__e>();
        for (Case currentCase : (List<Case>) Trigger.new) {

            if (currentCase.PJN_Care_Plan_Start_Status__c == 'PJN_Pending'
                && (Trigger.isInsert || newlyPendingIds.contains(currentCase.Id))) {
                programStartEvents.add(
                    new PJN_Program_Event__e( PJN_CarePlan__c = currentCase.Id)
                );
            }
        }
        System.debug('programStartEvents ' + programStartEvents);
        if (!programStartEvents.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(programStartEvents);

            for (Integer i=0; i<results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(programStartEvents[i].PJN_CarePlan__c);
                    Case erroredCase = (Case) Trigger.newMap.get(programStartEvents[i].PJN_CarePlan__c);
                    String error = PUBLISHING_ERROR + getHtmlErrorString(results[i]);
                    erroredCase.addError(error, true);
                }
            }
        }
    }

    private String getHtmlErrorString( Database.SaveResult result) {
        List<String> errors = new List<String>();
        for (Database.Error err : result.getErrors()) {
            errors.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(errors, '; ');
    }
}