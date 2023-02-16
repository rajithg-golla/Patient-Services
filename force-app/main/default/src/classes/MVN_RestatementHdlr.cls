/**
 * @author Mavens
 * @date July 2021
 * @description Handler to support logic for sending restatements to IntegriChain
 * @group hub-status-export
 */
public with sharing class MVN_RestatementHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    private static Boolean hasRun = false;

    /**
     * Handle the trigger call BEFORE UPDATE
     */
    public void handle() {

        Boolean isAllowed = Trigger.isBefore && Trigger.isUpdate && !hasRun;       

        if(!isAllowed) {
            return;
        }

        hasRun = true;
        for (PJN_Event__c event : (List<PJN_Event__c>)Trigger.new) {
            if (this.isThisARestatement(event)) {
                if (!event.MVN_Single_Restatement__c) {
                    applyRestatement(event);
                }
                event.MVN_Restatement__c = 'Y';
            }
        }
    }

    /**
     * @description Returns true if the event is a restatement that needs to be processed
     * @param  event event being updated
     * @return  `Boolean`
     */
    private Boolean isThisARestatement(PJN_Event__c event) {
        Id restatementStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                                .get('MVN_Therapy_Status_Restatement').getRecordTypeId();
        return (event.RecordTypeId == restatementStatusUpdateRT &&
                ((event.MVN_Restatement_Start_Date__c != null && event.MVN_Restatement_End_Date__c != null)
                || event.MVN_Single_Restatement__c == true));
    }

    /**
     * @description Update Therapy Status Events within the Restatement Start and End Date
     * @param  event event being restated
     */
    private void applyRestatement(PJN_Event__c event) {
        List<SObject> eventsToRestate = getEventsToRestate(event);
        List<String> listOfUpdatedFields = getListOfUpdatedFields(event);

        if (listOfUpdatedFields.isEmpty()) {
            return;
        }
        
        SObject newEventObject = Trigger.newMap.get(event.Id);
        for (SObject thisEvent : eventsToRestate) {
            for (String updatedField : listOfUpdatedFields) {
                thisEvent.put(updatedField, newEventObject.get(updatedField));
            }
            thisEvent.put('MVN_Restatement__c', 'Y');
        }
       
        update eventsToRestate;
    }

    /**
     * @description get list of Therapy Status Events that were created within Restatement Start
     *              and End Dates
     * @param  event event being restated
     * @return `List<PJN_Event__c>`
     */
    private List<PJN_Event__c> getEventsToRestate(PJN_Event__c event) {
        Id restatementStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                                .get('MVN_Therapy_Status_Restatement').getRecordTypeId();
        Id therapyStatusUpdateRT = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName()
                                                .get('PJN_Therapy_Status_Update').getRecordTypeId();
        return [
            SELECT
                Id
            FROM
                PJN_Event__c
            WHERE
                CreatedDate >= :event.MVN_Restatement_Start_Date__c
            AND
                CreatedDate < :event.MVN_Restatement_End_Date__c.addDays(1)
            AND
                (RecordTypeId = :restatementStatusUpdateRT
                OR
                RecordTypeId = :therapyStatusUpdateRT)
            AND
                PJN_Case__c =: event.PJN_Case__c
            AND
                Id != :event.Id
        ];

    }


    private List<String> getListOfUpdatedFields(PJN_Event__c event) {
        SObject oldEventObject = Trigger.oldMap.get(event.Id);
        SObject newEventObject = Trigger.newMap.get(event.Id);

        List<String> listOfUpdatedFields = new List<String>();

        List<Schema.FieldSetMember> restatementFields = Schema.SObjectType.PJN_Event__c.fieldSets.MVN_Restatement_Fields.getFields();
        system.debug(restatementFields);
        for (Schema.FieldSetMember restatementField : restatementFields) {
            String restatementFieldpath = restatementField.fieldpath;
            if (oldEventObject.get(restatementFieldpath) != newEventObject.get(restatementFieldpath)) {
                listOfUpdatedFields.add(restatementFieldpath);
            }
        }
        return listOfUpdatedFields;
    }

}