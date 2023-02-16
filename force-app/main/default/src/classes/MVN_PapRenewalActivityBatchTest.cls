/**
 * @author      Mavens
 * @date        July 28, 2021
 * @description Unit tests for MVN_PapRenewalActivityBatch.
 */
@IsTest
private class MVN_PapRenewalActivityBatchTest {

    private static final String CRON_EXP = '0 0 0 3 9 ? ' + System.now().addYears(1).year();

    @TestSetup
    static void makeData() {
        createAssistancePrograms();
    }

    @IsTest
    static void testIfSchedulesCorrectly() {
        Test.startTest();
            // Schedule the test job
            String jobId = System.schedule('MVN_PapRenewalActivityBatch', CRON_EXP, new MVN_PapRenewalActivityBatch());

            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

            // Verify the expressions are the same
            System.assertEquals(CRON_EXP, ct.CronExpression, 'Expressions should be the same.');

            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered, 'Times triggered should be 0. Job should not run.');

            // Verify the next time the job will run
            System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime), 'Dates should match.');
        Test.stopTest();
    }

    @IsTest
    static void testIfActivtiesCreated() {
        Test.startTest();
        Database.executeBatch(new MVN_PapRenewalActivityBatch());
        Test.stopTest();

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertEquals(2, [SELECT Id FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'Two activities should have been inserted.');

        Id userId = [SELECT Id FROM User WHERE Alias = 'Testy' LIMIT 1][0].Id;
        for (Case activity : [SELECT OwnerId FROM Case WHERE RecordTypeId = :activityRecordTypeId]) {
            System.assertEquals(userId, activity.OwnerId, 'OwnerId should match the test user.');
        }
    }


    @IsTest
    static void testShouldFailWithNonMatchingDates() {

        List<PJN_Assistance_Program__c> programs = new List<PJN_Assistance_Program__c>();
        for (PJN_Assistance_Program__c program : [SELECT PJN_Effective_Date__c FROM PJN_Assistance_Program__c]) {
            program.PJN_Effective_Date__c = Date.today();
            programs.add(program);
        }
        update programs;

        Test.startTest();
        Database.executeBatch(new MVN_PapRenewalActivityBatch());
        Test.stopTest();

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertEquals(0, [SELECT Id FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'No activities should have been created.');
    }

    private static void createAssistancePrograms() {

        // insert User that will be used as Owner
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1][0];
        User testUser = new User(
            LastName = 'Testerson',
            FirstName = 'Testy',
            Email = 'testerson@testcode.com',
            Username= 'testerson@testcode.com.test',
            ProfileId = adminProfile.id,
            Alias = 'testy',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocalesIdKey='en_US',
            TimezonesIdKey='America/Los_Angeles',
            Street = 'Test Street',
            MobilePhone = '12345678',
            Phone = '12345678'
        );
        insert testUser;

        // insert Care Plan
        Case carePlan = new Case (
            OwnerId = testUser.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Open',
            MVN_Coordinator__c = testUser.Id
        );
        insert carePlan;

        // insert Assistance Programs
        Id recordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Patient_Assistance_Program').getRecordTypeId();
        Id lockedrecordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Patient_Assistance_Program_Locked').getRecordTypeId();
        Date effectiveDate = Date.today().addDays(-300);

        insert new List<PJN_Assistance_Program__c>{
            new PJN_Assistance_Program__c(
                MVN_Copay_Member_Id__c='9610834643', 
                MVN_Eligibility_Type__c = 'Exception',
                PJN_Care_Plan__c = carePlan.Id, 
                PJN_Effective_Date__c = effectiveDate,
                PJN_Outcome__c = 'Eligible',
                RecordTypeId = recordTypeId),
            new PJN_Assistance_Program__c(
                MVN_Copay_Member_Id__c='9137243527', 
                MVN_Eligibility_Type__c = 'Exception',
                PJN_Care_Plan__c = carePlan.Id, 
                PJN_Effective_Date__c = effectiveDate,
                PJN_Outcome__c = 'Eligible',
                RecordTypeId = lockedRecordTypeId)
        };
    }
}