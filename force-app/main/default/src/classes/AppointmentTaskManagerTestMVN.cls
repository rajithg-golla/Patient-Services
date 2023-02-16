/**
 * @author      Mavens
 * @group       AppointmentTaskManagerMVN
 * @description Unit tests for AppointmentTaskManagerMVN
 * 
 */


/* ASSUMPTION: This test class assumes that business hours have been loaded
 *             as EST time zone, 24 hours a day M-F
 */

@isTest
public class AppointmentTaskManagerTestMVN {
    
    private static final Integer DATA_SIZE = 200;


    @TestSetup
    static void makeData(){
        User DRSpecialist = TestUtilityMVN.getDRProgramSpecialist();
        insert DRSpecialist;

        System.runAs(DRSpecialist) {
            List<Account> participants = new List<Account>();
            Id participantRecTypeId = SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get('Program_Participant_MVN')
                .getRecordTypeId();

            for (Integer i=0; i<DATA_SIZE; i++) {
                participants.add(
                    new Account(
                        LastName = 'Test' + i,
                        RecordTypeId = participantRecTypeId
                    )
                );
            }
            insert participants;

            List<Case> carePlans = new List<Case>();
            Id carePlanRecTypeId = SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('CarePlan')
                .getRecordTypeId();

            for (Account participant : participants) {
                carePlans.add(
                    new Case(
                        AccountId = participant.Id,
                        RecordTypeId = carePlanRecTypeId
                    )
                );
            }
            insert carePlans;
        }
    }

    @isTest
    private static void itShouldCreateNewTasksDayBeforeAndAfterAppointment() {
        List<Case> carePlans = [SELECT Id, Account.PersonContactId FROM Case];
        List<Appointment_MVN__c> appointments = new List<Appointment_MVN__c>();

        // get a wednesday in the future. ensures tasks are created the
        // day before and after
        Date futureWednesday = getFutureDay('wednesday').addDays(7);

        for (Case carePlan : carePlans) {
            appointments.add(
                new Appointment_MVN__c(
                    Care_Plan_MVN__c = carePlan.Id,
                    Appointment_Date_MVN__c = futureWednesday
                )
            );
        }

        Test.startTest();
        insert appointments;
        Test.stopTest();

        List<Task> reminderTasks = [
            SELECT Subject
            FROM Task 
            WHERE ActivityDate = :futureWednesday.addDays(-1)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, reminderTasks.size(), 'followups not created 1 day before wednesday');
        for (Task reminderTask : reminderTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Reminder_MVN, reminderTask.Subject);
        }

         List<Task> followupTasks = [
            SELECT Subject 
            FROM Task 
            WHERE ActivityDate = :futureWednesday.addDays(1)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, followupTasks.size(), 'followups not created 1 day later than wednesday');
        for (Task followUpTask : followupTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Follow_Up_MVN, followUpTask.Subject);
        }
    }
    
    @isTest
    private static void itShouldCreateNewTasksDayBeforeAndMondayAfterFridayAppt() {
        List<Case> carePlans = [SELECT Id, Account.PersonContactId FROM Case];
        List<Appointment_MVN__c> appointments = new List<Appointment_MVN__c>();

        // get a wednesday in the future. ensures tasks are created the
        // day before and after
        Date futureFriday = getFutureDay('friday').addDays(7);

        for (Case carePlan : carePlans) {
            appointments.add(
                new Appointment_MVN__c(
                    Care_Plan_MVN__c = carePlan.Id,
                    Appointment_Date_MVN__c = futureFriday
                )
            );
        }

        Test.startTest();
        insert appointments;
        Test.stopTest();

        List<Task> reminderTasks = [
            SELECT Subject 
            FROM Task 
            WHERE ActivityDate = :futureFriday.addDays(-1)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, reminderTasks.size(), 'followups not created 1 day before friday');
        for (Task reminderTask : reminderTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Reminder_MVN, reminderTask.Subject);
        }

        List<Task> followupTasks = [
            SELECT Subject
            FROM Task 
            WHERE ActivityDate = :futureFriday.addDays(3)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, followupTasks.size(), 'followups not created 3 days later than friday');
        for (Task followUpTask : followupTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Follow_Up_MVN, followUpTask.Subject);
        }
    }

    @isTest
    private static void itShouldCreateNewTasksFridayBeforeAndTuedayAfterMondayAppt() {
        List<Case> carePlans = [SELECT Id, Account.PersonContactId FROM Case];
        List<Appointment_MVN__c> appointments = new List<Appointment_MVN__c>();

        // get a wednesday in the future. ensures tasks are created the
        // day before and after
        Date futureMonday = getFutureDay('monday').addDays(7);

        for (Case carePlan : carePlans) {
            appointments.add(
                new Appointment_MVN__c(
                    Care_Plan_MVN__c = carePlan.Id,
                    Appointment_Date_MVN__c = futureMonday
                )
            );
        }

        Test.startTest();
        insert appointments;
        Test.stopTest();

        List<Task> reminderTasks = [
            SELECT Subject
            FROM Task 
            WHERE ActivityDate = :futureMonday.addDays(-3)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, reminderTasks.size(), 'followups not created 3 days before monday');
        for (Task reminderTask : reminderTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Reminder_MVN, reminderTask.Subject);
        }

        List<Task> followupTasks =  [
            SELECT Subject 
            FROM Task 
            WHERE ActivityDate = :futureMonday.addDays(1)
            AND Owner.Alias = 'progSpec'
        ];
        System.assertEquals(DATA_SIZE, followupTasks.size(), 'followups not created 1 day later than monday');
        for (Task followUpTask : followupTasks) {
            System.assertEquals(Label.Appointment_Creation_Task_Follow_Up_MVN, followUpTask.Subject);
        }
    }

    @isTest
    private static void itShouldNotCreateNewTasksforAppointmentInPast() {
        List<Case> carePlans = [SELECT Id, Account.PersonContactId FROM Case];
        List<Appointment_MVN__c> appointments = new List<Appointment_MVN__c>();

        for (Case carePlan : carePlans) {
            appointments.add(
                new Appointment_MVN__c(
                    Care_Plan_MVN__c = carePlan.Id,
                    Appointment_Date_MVN__c = Date.today().addDays(-1)
                )
            );
        }

        Test.startTest();
        insert appointments;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Task], 'tasks were created when they shouldn\'t be');
    }


    private static Date getFutureDay(String day) {
        Map<String, Integer> dayMap = new Map<String, Integer> {
            'sunday' => 0,
            'monday'=> 1,
            'tuesday' => 2,
            'wednesday' => 3,
            'thursday' => 4,
            'friday' => 5,
            'saturday' => 6
        };

        Date knownSunday = date.newInstance(2013, 1, 6);
        Integer todayValue = Math.mod(Math.abs(knownSunday.daysBetween(Date.today())),7);
        Integer futureValue = dayMap.get(day) - todayValue;
        if (futureValue < 0) {
            futureValue += 7;
        }

        return Date.today().addDays(futureValue);
    }
}