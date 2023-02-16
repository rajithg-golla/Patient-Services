/**
 * @author      Mavens
 * @group       AppointmentTaskManagerMVN
 * @description On appointment creation add appropriate reminder and followup tasks
 */
public with sharing class AppointmentTaskManagerMVN implements PJN_TriggerDispatcher.HandlerInterface {

    Map<Id, Account> accountMap;
    Map<Id, Case> carePlanMap;

    public void handle() {
        getAccountsAndCarePlans();

        List<Task> tasks = new List<Task>();

        BusinessDaysMVN businessDays = new BusinessDaysMVN();

        Id carePlanTaskRecordTypeId = SObjectType.Task
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlanTask')
            .getRecordTypeId();

        for (Appointment_MVN__c appointment : (List<Appointment_MVN__c>) Trigger.new) {
            Date appointmentDate = appointment.Appointment_Date_MVN__c;

            // Determine reminder date, skip reminder if it would happen today or in past
            Date reminderDate;
            Date priorDay = appointmentDate.addDays(-1);

            // determin the who Id
            Account who = accountMap.get(appointment.Account_MVN__c);
            Id whoId;
            if (who != null) {
                whoId = who.PersonContactId;
            }

            Id ownerId = UserInfo.getUserId();
            Case carePlan = carePlanMap.get(appointment.Care_Plan_MVN__c);
            if (carePlan != null) {
                ownerId = carePlan.OwnerId;
            }

            while (reminderDate == null) {
                if ( priorDay <= Date.today()) {
                    break;
                }
                if (businessDays.isBusinessDay(priorDay)) {
                    reminderDate = priorDay;
                    break;
                }
                priorDay = priorDay.addDays(-1);
            }

            if (reminderDate != null) {
                tasks.add(
                    new Task(
                        Subject = Label.Appointment_Creation_Task_Reminder_MVN,
                        ActivityDate = reminderDate,
                        WhatId = appointment.Care_Plan_MVN__c,
                        WhoId = whoId,
                        RecordTypeId = carePlanTaskRecordTypeId,
                        Status = 'Open',
                        OwnerId = ownerId
                    )
                );
            }

            //determine followup date, create follow up task if appointment is today
            // or in the future
            Date followupDate = businessDays.nextBusinessDay(appointmentDate.addDays(1));
            if (appointmentDate > Date.today()) {
                tasks.add(
                    new Task(
                        Subject = Label.Appointment_Creation_Task_Follow_Up_MVN,
                        ActivityDate = followupDate,
                        WhatId = appointment.Care_Plan_MVN__c,
                        WhoId = whoId,
                        RecordTypeId = carePlanTaskRecordTypeId,
                        Status = 'Open',
                        OwnerId = ownerId
                    )
                );
            }
        }

        insert tasks;
    }

    private void getAccountsAndCarePlans() {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> carePlanIds = new Set<Id>();

        for (Appointment_MVN__c appointment : (List<Appointment_MVN__c>) Trigger.new) {
            accountIds.add(appointment.Account_MVN__c);
            carePlanIds.add(appointment.Care_Plan_MVN__c);
        }

        accountMap = new Map<Id, Account>([
            SELECT Id, PersonContactId FROM Account WHERE Id IN :accountIds
        ]);

        carePlanMap = new Map<Id, Case>([
            SELECT Id, OwnerId FROM Case WHERE Id IN :carePlanIds
        ]);
    }
}