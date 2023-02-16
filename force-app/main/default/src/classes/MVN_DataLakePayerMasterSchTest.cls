/**
 * @author      Mavens
 * @group       DataLake
 * @description Test for MVN_DataLakePayerMasterSch
 */
@IsTest
private class MVN_DataLakePayerMasterSchTest {

    private static final String CRON_EXP = '0 0 0 3 9 ? ' + System.now().addYears(1).year();

    @IsTest
    static void testIfSchedulesCorrectly() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('MVN_DataLakePayerMasterSch', CRON_EXP, new MVN_DataLakePayerMasterSch());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        // Verify the next time the job will run
        System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
}