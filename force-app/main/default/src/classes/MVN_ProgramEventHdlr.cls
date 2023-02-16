/**
* @author Mavens
* @description Trigger handler for Activites and Program Problems to create events
* @group Events
*/
public without sharing class MVN_ProgramEventHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    @TestVisible
    private static MVN_ProgramEventQuery programEventQuery = new MVN_ProgramEventQuery();

    public void handle() {
        SObject firstRecord = Trigger.new.get(0);

        if (firstRecord.getSObjectType() == HealthCloudGA__CarePlanProblem__c.getSObjectType()) {
            handleProblems();
        }

        if (firstRecord.getSObjectType() == Case.getSObjectType()) {
            handleCases();
        }

        if (firstRecord.getSObjectType() == PJN_Fulfillment_Request__c.getSObjectType()) {
            handleFulfillmentRequests();
        }
    }

    private void handleProblems() {
        Map<String, List<MVN_Program_Event__mdt>> problemEventsByProblemDevName = programEventQuery.forProblems();

        List<PJN_Event__c> newEvents = new List<PJN_Event__c>();

        List<HealthCloudGA__CarePlanProblem__c> problems = [
            SELECT
                Id,
                PJN_Program_Problem_DeveloperName__c,
                PJN_Status__c,
                HealthCloudGA__CarePlan__c,
                HealthCloudGA__CarePlan__r.AccountId,
                HealthCloudGA__CarePlan__r.PJN_Physician__c,
                HealthCloudGA__CarePlan__r.MVN_HIPAA_Consent__c,
                HealthCloudGA__CarePlan__r.PJN_Active_Coverage_Investigation__c,
                HealthCloudGA__CarePlan__r.PJN_Primary_Member_Plan__c,
                HealthCloudGA__CarePlan__r.PJN_Secondary_Member_Plan__c,
                HealthCloudGA__CarePlan__r.MVN_Copay_Assistance_Program__c,
                HealthCloudGA__CarePlan__r.MVN_Treatment_Site__c,
                HealthCloudGA__CarePlan__r.MVN_Program_Consent__c,
                HealthCloudGA__CarePlan__r.MVN_PAP_Consent__c,
                HealthCloudGA__CarePlan__r.MVN_Organization__c,
                HealthCloudGA__CarePlan__r.PJN_Primary_Prescription__c,
                HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c,
                HealthCloudGA__CarePlan__r.PJN_Therapy_Status__c,
                HealthCloudGA__CarePlan__r.OwnerId
            FROM
                HealthCloudGA__CarePlanProblem__c
            WHERE
                Id IN :Trigger.new
            ORDER BY HealthCloudGA__SortOrder__c ASC
        ];

        for (HealthCloudGA__CarePlanProblem__c problem : problems) {
            if (!problemStatusIsChanged(problem)) {
                continue;
            }

            String programName = problem.PJN_Program_Problem_DeveloperName__c;
            if (problemEventsByProblemDevName.containsKey(programName)) {
                List<MVN_Program_Event__mdt> eventDetails = problemEventsByProblemDevName.get(programName);
                for (MVN_Program_Event__mdt eventDetail : eventDetails) {
                    if (eventDetail.MVN_Record_Status__c == problem.PJN_Status__c
                        && eventDetail.MVN_Program_Developer_Name__c == problem.PJN_Program_Problem_DeveloperName__c) {
                        PJN_Event__c newEvent = createEvent(eventDetail);
                        newEvent.PJN_Patient__c = problem.HealthCloudGA__CarePlan__r.AccountId;
                        newEvent.PJN_Case__c = problem.HealthCloudGA__CarePlan__c;
                        newEvent.MVN_Physician__c = problem.HealthCloudGA__CarePlan__r.PJN_Physician__c;
                        newEvent.MVN_HIPAA_Consent__c = problem.HealthCloudGA__CarePlan__r.MVN_HIPAA_Consent__c;
                        newEvent.MVN_Active_Coverage_Investigation__c = problem.HealthCloudGA__CarePlan__r.PJN_Active_Coverage_Investigation__c;
                        newEvent.MVN_Primary_Member_Plan__c = problem.HealthCloudGA__CarePlan__r.PJN_Primary_Member_Plan__c;
                        newEvent.MVN_Secondary_Member_Plan__c = problem.HealthCloudGA__CarePlan__r.PJN_Secondary_Member_Plan__c;
                        newEvent.MVN_Copay_Assistance_Program__c = problem.HealthCloudGA__CarePlan__r.MVN_Copay_Assistance_Program__c;
                        newEvent.MVN_Treatment_Site__c = problem.HealthCloudGA__CarePlan__r.MVN_Treatment_Site__c;
                        newEvent.MVN_Program_Consent__c = problem.HealthCloudGA__CarePlan__r.MVN_Program_Consent__c;
                        newEvent.MVN_PAP_Consent__c = problem.HealthCloudGA__CarePlan__r.MVN_PAP_Consent__c;
                        newEvent.MVN_Practice__c = problem.HealthCloudGA__CarePlan__r.MVN_Organization__c;
                        newEvent.MVN_Prescription__c = problem.HealthCloudGA__CarePlan__r.PJN_Primary_Prescription__c;
                        newEvent.PJN_Program_DeveloperName__c = problem.HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c;
                        newEvent.OwnerId = problem.HealthCloudGA__CarePlan__r.OwnerId;
                        if (eventDetail.MVN_Use_Care_Plan_current_Therapy_Status__c) {
                            newEvent.PJN_New_Therapy_Status__c = problem.HealthCloudGA__CarePlan__r.PJN_Therapy_Status__c;
                        }
                        newEvents.add(newEvent);
                    }
                }
            }
        }
        insert newEvents;
    }

    private void handleCases() {
        Map<String, List<MVN_Program_Event__mdt>> activityEventsByProgram = programEventQuery.forActivities();

        List<PJN_Event__c> newEvents = new List<PJN_Event__c>();

        List<Case> activities = [
            SELECT
                Id,
                Status,
                AccountId,
                PJN_Program_DeveloperName__c,
                PJN_Program_Case_DeveloperName__c,
                ParentId,
                Parent.PJN_Physician__c,
                Parent.MVN_HIPAA_Consent__c,
                Parent.PJN_Active_Coverage_Investigation__c,
                Parent.PJN_Primary_Member_Plan__c,
                Parent.PJN_Secondary_Member_Plan__c,
                Parent.MVN_Copay_Assistance_Program__c,
                Parent.MVN_Treatment_Site__c,
                Parent.MVN_Program_Consent__c,
                Parent.MVN_PAP_Consent__c,
                Parent.MVN_Organization__c,
                Parent.PJN_Primary_Prescription__c,
                Parent.PJN_Therapy_Status__c,
                Parent.OwnerId
            FROM
                Case
            WHERE
                Id IN : Trigger.new
            AND
                RecordType.DeveloperName = 'PJN_Activity'
        ];

        for (Case activity : activities) {
            if (!activityStatusIsChanged(activity)) {
                continue;
            }

            String caseDeveloperName = activity.PJN_Program_Case_DeveloperName__c;
            if (activityEventsByProgram.containsKey(caseDeveloperName)) {
                List<MVN_Program_Event__mdt> eventDetails = activityEventsByProgram.get(caseDeveloperName);
                for (MVN_Program_Event__mdt eventDetail : eventDetails) {
                    if (eventDetail.MVN_Record_Status__c == activity.Status
                        && eventDetail.MVN_Program_Developer_Name__c  == activity.PJN_Program_Case_DeveloperName__c) {
                        PJN_Event__c newEvent = createEvent(eventDetail);
                        newEvent.PJN_Patient__c = activity.AccountId;
                        newEvent.PJN_Case__c = activity.ParentId;
                        newEvent.MVN_Physician__c = activity.Parent.PJN_Physician__c;
                        newEvent.MVN_HIPAA_Consent__c = activity.Parent.MVN_HIPAA_Consent__c;
                        newEvent.MVN_Active_Coverage_Investigation__c = activity.Parent.PJN_Active_Coverage_Investigation__c;
                        newEvent.MVN_Primary_Member_Plan__c = activity.Parent.PJN_Primary_Member_Plan__c;
                        newEvent.MVN_Secondary_Member_Plan__c = activity.Parent.PJN_Secondary_Member_Plan__c;
                        newEvent.MVN_Copay_Assistance_Program__c = activity.Parent.MVN_Copay_Assistance_Program__c;
                        newEvent.MVN_Treatment_Site__c = activity.Parent.MVN_Treatment_Site__c;
                        newEvent.MVN_Program_Consent__c = activity.Parent.MVN_Program_Consent__c;
                        newEvent.MVN_PAP_Consent__c = activity.Parent.MVN_PAP_Consent__c;
                        newEvent.MVN_Practice__c = activity.Parent.MVN_Organization__c;
                        newEvent.MVN_Prescription__c = activity.Parent.PJN_Primary_Prescription__c;
                        newEvent.OwnerId = activity.Parent.OwnerId;
                        newEvent.PJN_Program_DeveloperName__c = activity.PJN_Program_DeveloperName__c;
                        if (eventDetail.MVN_Use_Care_Plan_current_Therapy_Status__c) {
                            newEvent.PJN_New_Therapy_Status__c = activity.Parent.PJN_Therapy_Status__c;
                        }
                        newEvents.add(newEvent);
                    }
                }
            }
        }
        insert newEvents;
    }

    private void handleFulfillmentRequests() {
        Map<String, List<MVN_Program_Event__mdt>> fulfillmentRequestEventsByProgram = programEventQuery.forFulfillmentRequests();

        List<PJN_Event__c> newEvents = new List<PJN_Event__c>();

        List<PJN_Fulfillment_Request__c> fulfillmentRequests = [
            SELECT
                Id,
                PJN_Patient__c,
                PJN_Fulfillment_Request_Status__c,
                RecordType.DeveloperName,
                PJN_Care_Plan__c,
                PJN_Care_Plan__r.OwnerId,
                PJN_Care_Plan__r.PJN_Therapy_Status__c,
                PJN_Care_Plan__r.PJN_Program_DeveloperName__c
            FROM
                PJN_Fulfillment_Request__c
            WHERE
                Id IN : Trigger.new
            AND
                RecordType.DeveloperName IN ('MVN_NCP_Triage', 'PJN_SP_Triage')
        ];

        for (PJN_Fulfillment_Request__c fulfillmentRequest : fulfillmentRequests) {
            if (!fulfillmentRequestStatusIsChanged(fulfillmentRequest)) {
                continue;
            }

            if (fulfillmentRequestEventsByProgram.containsKey(fulfillmentRequest.RecordType.DeveloperName)) {
                List<MVN_Program_Event__mdt> eventDetails = fulfillmentRequestEventsByProgram.get(fulfillmentRequest.RecordType.DeveloperName);
                for (MVN_Program_Event__mdt eventDetail : eventDetails) {
                    if (eventDetail.MVN_Record_Status__c == fulfillmentRequest.PJN_Fulfillment_Request_Status__c
                        && eventDetail.MVN_Program_Developer_Name__c  == fulfillmentRequest.RecordType.DeveloperName) {
                        PJN_Event__c newEvent = createEvent(eventDetail);
                        newEvent.PJN_Patient__c = fulfillmentRequest.PJN_Patient__c;
                        newEvent.PJN_Case__c = fulfillmentRequest.PJN_Care_Plan__c;
                        newEvent.PJN_Fulfillment_Request__c = fulfillmentRequest.Id;
                        newEvent.OwnerId = fulfillmentRequest.PJN_Care_Plan__r.OwnerId;
                        newEvent.PJN_Program_DeveloperName__c = fulfillmentRequest.PJN_Care_Plan__r.PJN_Program_DeveloperName__c;
                        if (eventDetail.MVN_Use_Care_Plan_current_Therapy_Status__c) {
                            newEvent.PJN_New_Therapy_Status__c = fulfillmentRequest.PJN_Care_Plan__r.PJN_Therapy_Status__c;
                        }
                        newEvents.add(newEvent);
                    }
                }
            }
        }

        insert newEvents;
    }

    private Boolean problemStatusIsChanged(HealthCloudGA__CarePlanProblem__c problem) {
        if (Trigger.isInsert) {
            return true; // newly inserted
        }

        HealthCloudGA__CarePlanProblem__c oldValue = (HealthCloudGA__CarePlanProblem__c) Trigger.oldMap.get(problem.Id);
        if (Trigger.isUpdate && oldValue.PJN_Status__c != problem.PJN_Status__c) {
            return true; // status value updated
        }

        return false;
    }

    private Boolean activityStatusIsChanged(Case activity) {
        if (Trigger.isInsert) {
            return true; // newly inserted
        }

        Case oldValue = (Case) Trigger.oldMap.get(activity.Id);
        if (Trigger.isUpdate && oldValue.Status != activity.Status) {
            return true; // status value updated
        }

        return false;
    }

    private Boolean fulfillmentRequestStatusIsChanged(PJN_Fulfillment_Request__c fulfillmentRequest) {
        if (Trigger.isInsert) {
            return true; // newly inserted
        }

        PJN_Fulfillment_Request__c oldValue = (PJN_Fulfillment_Request__c) Trigger.oldMap.get(fulfillmentRequest.Id);
        if (Trigger.isUpdate && oldValue.PJN_Fulfillment_Request_Status__c != fulfillmentRequest.PJN_Fulfillment_Request_Status__c) {
            return true; // status value updated
        }

        return false;
    }

    private PJN_Event__c createEvent(MVN_Program_Event__mdt eventDetail) {
        return new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_New_Therapy_Status__c = eventDetail.MVN_Therapy_Status__c,
            PJN_New_Therapy_Sub_Status__c = eventDetail.MVN_Therapy_Sub_Status__c,
            PJN_Status_Date__c = Date.today()
        );
    }
}