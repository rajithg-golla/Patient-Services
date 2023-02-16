/**
* @author Mavens
* @description Queries for program event records
* @group Events
*/
public with sharing class MVN_ProgramEventQuery {

    public Map<String, List<MVN_Program_Event__mdt>> forProblems() {
        return query(SObjectType.HealthCloudGA__CarePlanProblem__c.getName());
    }

    public Map<String, List<MVN_Program_Event__mdt>> forActivities() {
        return query(SObjectType.Case.getName());
    }

    public Map<String, List<MVN_Program_Event__mdt>> forFulfillmentRequests() {
        return query(SObjectType.PJN_Fulfillment_Request__c.getName());
    }

    private Map<String, List<MVN_Program_Event__mdt>> query(String sObjectName) {
        Map<String, List<MVN_Program_Event__mdt>> eventDetailsByDevName = new Map<String, List<MVN_Program_Event__mdt>>();

        List<MVN_Program_Event__mdt> eventDetailList = [
            SELECT
                MVN_Program_Developer_Name__c,
                MVN_Record_Status__c,
                MVN_SObject__c,
                MVN_Therapy_Status__c,
                MVN_Therapy_Sub_Status__c,
                MVN_Use_Care_Plan_current_Therapy_Status__c
            FROM
                MVN_Program_Event__mdt
            WHERE
                MVN_SObject__c = :sObjectName
        ];

        for (MVN_Program_Event__mdt eventDetail : eventDetailList) {
            if (!eventDetailsByDevName.containsKey(eventDetail.MVN_Program_Developer_Name__c)) {
                eventDetailsByDevName.put(
                    eventDetail.MVN_Program_Developer_Name__c,
                    new List<MVN_Program_Event__mdt>()
                );
            }
            eventDetailsByDevName.get(eventDetail.MVN_Program_Developer_Name__c).add(eventDetail);
        }

        return eventDetailsByDevName;
    }
}