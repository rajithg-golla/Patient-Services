/**
 * @author      Mavens
 * @date        July 28, 2021
 * @description Unit tests for MVN_PaReauthActivityBatch.
 */
@IsTest
private class MVN_PaReauthActivityBatchTest {

    private static final String CRON_EXP = '0 0 0 3 9 ? ' + System.now().addYears(1).year();

    @TestSetup
    static void makeData() {
        createData();
    }

    @IsTest
    static void testIfSchedulesCorrectly() {
        Test.startTest();
            // Schedule the test job
            String jobId = System.schedule('MVN_PaReauthActivityBatch', CRON_EXP, new MVN_PaReauthActivityBatch());

            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT CronExpression, NextFireTime, TimesTriggered FROM CronTrigger WHERE id = :jobId];

            // Verify the expressions are the same
            System.assertEquals(CRON_EXP, ct.CronExpression, 'Expressions should be the same.');

            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered, 'Times triggered should be 0');

            // Verify the next time the job will run
            System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime), 'Dates should match');
        Test.stopTest();
    }

    @IsTest
    static void testIfActivtiesCreated() {
        Test.startTest();
        Database.executeBatch(new MVN_PaReauthActivityBatch());
        Test.stopTest();

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertEquals(2, [SELECT Id FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'Two activities should have been inserted.');

        Id ownerId = [SELECT Id FROM User WHERE Alias = 'owner' LIMIT 1][0].Id;
        Id coordinatorId = [SELECT Id FROM User WHERE Alias = 'coord' LIMIT 1][0].Id;
        System.assertEquals(1, [SELECT Id FROM Case WHERE OwnerId = :ownerId AND RecordTypeId = :activityRecordTypeId].size(), 'One activity should have been inserted with OwnerId matching the OwnerId from CarePlans.');
        System.assertEquals(1, [SELECT Id FROM Case WHERE OwnerId = :coordinatorId AND RecordTypeId = :activityRecordTypeId].size(), 'One activity should have been inserted with OwnerId matching the MVN_Coordinator__c from CarePlans.');
    }

    @IsTest
    static void testShouldFailWithNonMatchingDates() {

        List<PJN_Prior_Authorization__c> priorAuths = new List<PJN_Prior_Authorization__c>();
        for (PJN_Prior_Authorization__c priorAuth : [SELECT PJN_Effective_Date__c FROM PJN_Prior_Authorization__c]) {
            priorAuth.PJN_Expiration_Date__c = Date.today();
            priorAuths.add(priorAuth);
        }
        update priorAuths;

        Test.startTest();
        Database.executeBatch(new MVN_PaReauthActivityBatch());
        Test.stopTest();

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertEquals(0, [SELECT Id FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'No activities should have been created.');
    }

    private static void createData() {

        // profile for our users, just using admin to avoid any unforeseen permission issues
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1][0];

        // build User that will be used as OwnerId
        User ownerUser = buildUser('Owner', adminProfile.Id);

        // build User that will be used as Coordinator
        User coordinatorUser = buildUser('Coordinator', adminProfile.Id);

        // insert users
        insert new List<User>{coordinatorUser, ownerUser};

        // insert test account
        Account acct = new Account(
            FirstName = 'Test',
            LastName = 'Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        insert acct;

        // create careplan with coordinator
        Case carePlan0 = new Case (
            AccountId = acct.Id,
            OwnerId = ownerUser.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Open',
            MVN_Coordinator__c = coordinatorUser.Id,
            PJN_Therapy_Status__c = 'Active'
        );

        // create careplan without coordinator
        Case carePlan1 = new Case (
            AccountId = acct.Id,
            OwnerId = ownerUser.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Open',
            PJN_Therapy_Status__c = 'Active'
        );

        // insert careplans
        insert new List<Case>{carePlan0,carePlan1};

        // create member plan that associates with carePlan0
        PJN_Member_Plan__c plan0 = new PJN_Member_Plan__c(
            PJN_Patient__c = acct.Id,
            PJN_Care_Plan__c = carePlan0.Id
        );

        // create member plan that associates with carePlan1
        PJN_Member_Plan__c plan1 = new PJN_Member_Plan__c(
            PJN_Patient__c = acct.Id,
            PJN_Care_Plan__c = carePlan1.Id
        );

        // insert member plans
        insert new List<PJN_Member_Plan__c>{plan0, plan1};

        // create dates
        Date effectiveDate = Date.today().addDays(-30);
        Date expirationDate = Date.today().addDays(35);

        // finally, we insert the Prior Auth records
        insert new List<PJN_Prior_Authorization__c>{
            new PJN_Prior_Authorization__c(
                PJN_Care_Plan__c = carePlan0.Id,
                PJN_Effective_Date__c = effectiveDate,
                PJN_Expiration_Date__c = expirationDate,
                PJN_Member_Plan__c = plan0.Id,
                PJN_Outcome__c = 'Approved'
            ),
            new PJN_Prior_Authorization__c(
                PJN_Care_Plan__c = carePlan1.Id,
                PJN_Effective_Date__c = effectiveDate,
                PJN_Expiration_Date__c = expirationDate,
                PJN_Member_Plan__c = plan1.Id,
                PJN_Outcome__c = 'Approved'
            )
        };
    }

    private static User buildUser(String name, Id profileId) {
        return new User(
            FirstName = 'Testy',
            LastName = name,
            Email = name.toLowerCase() + '@testcode.com',
            Username = name.toLowerCase() + 'coordinator@testcode.com.test',
            ProfileId = profileId,
            Alias = name.toLowerCase().substring(0, 5),
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocalesIdKey='en_US',
            TimezonesIdKey='America/Los_Angeles',
            Street = 'Test Street',
            MobilePhone = '12345678',
            Phone = '12345678'
        );
    }
}