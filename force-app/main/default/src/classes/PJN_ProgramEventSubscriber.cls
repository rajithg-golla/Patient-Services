public with sharing class PJN_ProgramEventSubscriber implements PJN_TriggerDispatcher.HandlerInterface {
    public static Map<Id, Case> carePlans;
    public static Map<Id, HealthCloudGA__CarePlanProblem__c> carePlanProblems;

    /**
     * handle before insert trigger context
     */
    public void handle() {
        try {
            handle(
                (List<PJN_Program_Event__e>) trigger.new
            );
        } catch(PJN_ProgramEventException programEventEx) {
            System.debug('programEventEx:: ' + programEventEx);
            System.debug('programEventEx:Message:: ' + programEventEx.getMessage());
            System.debug('programEventEx:Stacktrace:: ' + programEventEx.getStackTraceString());
            if(EventBus.TriggerContext.currentContext().retries < 4) {
                throw new EventBus.RetryableException('Retrying a ' + EventBus.TriggerContext.currentContext().retries + ' time.');
            }
        }
    }

    /**
     * handle
     * @param   List<PJN_Program_Event__e>      programEvents
     */
    public void handle(List<PJN_Program_Event__e> programEvents) {
        Set<Id> newCarePlanIds = new Set<Id>();
        for(PJN_Program_Event__e thisProgramEvent : programEvents) {
            newCarePlanIds.add(thisProgramEvent.PJN_CarePlan__c);
        }

        processNewCarePlansAsync(newCarePlanIds);
    }

    @future
    private static void processNewCarePlansAsync(Set<Id> newCarePlanIds) {
        processNewCarePlans(newCarePlanIds);
    }

    public static void processNewCarePlans(Set<Id> newCarePlanIds) {
        Savepoint sp = Database.setSavepoint();
        List<Case> carePlans = new List<Case>();
        try {
            // Organize care plans by program so they can be initialized in groups
            Map<String, List<Case>> carePlansByProgram = new Map<String, List<Case>>();
            for (Case carePlan : PJN_CarePlanQuery.queryByIds(newCarePlanIds).values()) {
                if (!carePlansByProgram.containsKey(carePlan.PJN_Program_DeveloperName__c)) {
                    carePlansByProgram.put(carePlan.PJN_Program_DeveloperName__c, new List<Case>());
                }
                carePlansByProgram.get(carePlan.PJN_Program_DeveloperName__c).add(carePlan);
            }

            List<Case> carePlansToUpdate = new List<Case>();
            List<CareProgramEnrollee> careProgramEnrollees = new List<CareProgramEnrollee>();
            List<HealthCloudGA__CarePlanProblem__c> newProblems = new List<HealthCloudGA__CarePlanProblem__c>();

            // initialize all care plans by program
            for (String programDevName : carePlansByProgram.keySet()) {
                List<Case> carePlansForProgram = carePlansByProgram.get(programDevName);
                carePlans.addAll(carePlansForProgram);
                PJN_CarePlanHdlr handler = new PJN_CarePlanHdlr(carePlansForProgram, programDevName);
                carePlansToUpdate.addAll(handler.initialize());
                careProgramEnrollees.addAll(handler.createCareProgramEnrollees());
                newProblems.addAll(handler.createProblems());
            }
            System.debug(JSON.serializePretty(carePlansToUpdate));
            update carePlansToUpdate;
            upsert careProgramEnrollees PJN_External_Id__c;
            insert newProblems;

            // care plan created and problems inserted
            // requery cases and start the care plans
            List<HealthCloudGA__CarePlanProblem__c> updatedProblems = new List<HealthCloudGA__CarePlanProblem__c>();
            List<Case> newCases = new List<Case>();
            for (Case carePlan : PJN_CarePlanQuery.queryByIds(newCarePlanIds).values()) {
                PJN_CarePlanWrapper wrapper = new PJN_CarePlanWrapper(carePlan);
                Map<HealthCloudGA__CarePlanProblem__c, List<Case>> returnedData = wrapper.start();
                updatedProblems.addAll(returnedData.keySet());
                for (HealthCloudGA__CarePlanProblem__c problem : returnedData.keySet()) {
                    newCases.addAll(returnedData.get(problem));
                }
            }

            update updatedProblems;
            insert newCases;
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            Database.rollback(sp);
            List<PJN_Log_Event__e> logEvents = new List<PJN_Log_Event__e>();
            for (Case carePlan : carePlans) {
                carePlan.PJN_Care_Plan_Start_Status__c = 'PJN_Error';
                logEvents.add(
                    new PJN_Log_Event__e(
                        PJN_Source__c = 'PJN_ProgramEventSubscriber Class',
                        PJN_Message__c = ex.getMessage(),
                        PJN_Exception_Type__c = 'Exception',
                        PJN_Exception_JSON__c = ex.getMessage() + '\n\n' + ex.getStackTraceString(),
                        PJN_SObject_Type__c = 'Case',
                        PJN_SObject_JSON__c = JSON.serializePretty(carePlan, true)
                    )
                );
            }
            EventBus.publish(logEvents);
            update carePlans;
        }
    }
}