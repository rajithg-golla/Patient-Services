/**
 * @author      Mavens
 * @group       DataLake
 * @description Test for MVN_DataLakeCMUpdateBatchSch
 */
@IsTest
private class MVN_DataLakeCMUpdateBatchSchTest {

    private static final Integer BULK_DATA = 50;
    private static final String CRON_EXP = '0 0 0 5 9 ? 2122';

    @TestSetup
    static void makeData(){
        Test.startTest();
        List<Account> accounts = new List<Account>();
        accounts.addAll(buildHCPs(BULK_DATA));
        accounts.addAll(buildHCOs(BULK_DATA));
        insert accounts;
        Test.stopTest();
    }

    private static List<Account> buildHCPs(Integer numberOfHCPs) {
        List<Account> hcps = new List<Account>();
        for (Integer i = 0; i < numberOfHCPs; i++) {
            hcps.add(
                new Account(
                    FirstName = 'John',
                    LastName = 'Smith',
                    HealthCloudGA__SourceSystemId__c = String.valueOf(i),
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId()
                )
            );
        }
        return hcps;
    }

    private static List<Account> buildHCOs(Integer numberOfHCOs) {
        List<Account> hcos = new List<Account>();
        for (Integer i = 0; i < numberOfHCOs; i++) {
            hcos.add(
                new Account(
                    Name = 'MAVENS HEALTH CLINIC',
                    HealthCloudGA__SourceSystemId__c = '100' + String.valueOf(i),
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId()
                )
            );
        }
        return hcos;
    }

    @IsTest
    static void testIfSchedulesCorrectly() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('MVN_DataLakeCMUpdateBatchSch', CRON_EXP, new MVN_DataLakeCMUpdateBatchSch());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        // Verify the next time the job will run
        System.assertEquals('2122-09-05 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }

    @IsTest
    static void testIfAccountsUpdatedCorrectly() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakeCMUpdateBatchSchMock.SearchSuccessMock());
        Id batchprocessid;
        Test.startTest();
        MVN_DataLakeCMUpdateBatchSch cmUpdateBatch = new MVN_DataLakeCMUpdateBatchSch();
        /* THIS NEEDS TO BE FIXED
        batchprocessid = Database.executeBatch(cmUpdateBatch, 100);
        Test.stopTest();
        List<Account> accounts = getAllAllowedAccounts();
        System.assert(!accounts.isEmpty(), 'Account cannot be empty.');
        for (Account thisAccount : accounts) {
            System.assertNotEquals(null, thisAccount.HealthCloudGA__SourceSystemId__c, 'External Id cannot be null.');
            System.assertEquals('A', thisAccount.PJN_Status__c, 'Account status must be Active.');
            if (thisAccount.isPersonAccount) {
                System.assertEquals('JOHN', thisAccount.FirstName, 'Firstname must be JOHN.');
                System.assertNotEquals('SMITH', thisAccount.LastName, 'LastName cannot be just SMITH.');
                System.assert(thisAccount.LastName.startsWith('SMITH'), 'LastName must start with SMITH');
                System.assertNotEquals(null, thisAccount.PJN_NPI__c, 'NPI cannot be null.');
            } else {
                System.assertNotEquals('MAVENS HEALTH CLINIC', thisAccount.Name, 'Name cannot be just MAVENS HEALTH CLINIC.');
                System.assert(thisAccount.Name.startsWith('MAVENS HEALTH CLINIC'), 'Name must start with MAVENS HEALTH CLINIC');
            }
        }
		*/
    }

    private static List<Account> getAllAllowedAccounts() {
        return [
            SELECT
                Id,
                HealthCloudGA__SourceSystemId__c,
                Name,
                FirstName,
                LastName,
                MiddleName,
                Salutation,
                PersonTitle,
                MVN_Birthdate__c,
                PJN_NPI__c,
                PJN_DEA__c,
                PJN_Status__c,
                IsPersonAccount
            FROM
                Account
            WHERE
                HealthCloudGA__SourceSystemId__c != null
            AND
                RecordType.DeveloperName IN :MVN_DataLakeCMUpdateBatchSch.RECORD_TYPES_ALLOWED
        ];
    }
}