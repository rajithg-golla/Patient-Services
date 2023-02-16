/**
 * @author      Mavens
 * @group       DataLake
 * @description Test for MVN_DataLakePayerMasterQueue
 */
@IsTest
private class MVN_DataLakePayerMasterQueueTest {

    @IsTest
    static void testIfGetPayerMasterCorrectlyIntoDatabase() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakePayerMasterMock.SearchSuccessMock());
        Test.startTest();
        System.enqueueJob(new MVN_DataLakePayerMasterQueue(null));
        Test.stopTest();
        List<Account> payers = getPayers();
        List<MVN_Payer_Plan__c> payerPlans = getPayerPlans();
        System.assertEquals(2000, payers.size(), 'It must ingest all the payers which has 2000 records.');
        System.assertEquals(2000, payerPlans.size(), 'It must ingest all the payer plans which has 2000 records.');
        for (Account payer : payers) {
            System.assertEquals('Abbott', payer.Name, 'Name must be Abbott.');
            System.assertNotEquals(null, payer.MVN_Precision_Id__c, 'Payer must have an external id');
            System.assertNotEquals(null, payer.MVN_Payer_Channel_Precision_Id__c, 'Payer Channel must have an external id');
            System.assertEquals('Abbott - Medicare', payer.MVN_Payer_Channel_Name__c, 'Channel Name must be Abbott - Medicare.');
            System.assertEquals(Date.valueOf('2021-06-01'), payer.MVN_SRC_Data_Month__c, 'SRC Data month must be 2021-06-01.');
            System.assertEquals(Date.valueOf('2021-06-01'), payer.MVN_PX_Data_Month__c, 'PX Data month must be 2021-06-01.');
            System.assertEquals(Date.valueOf('2021-06-14'), payer.MVN_PX_Delivery_Date__c, 'PX Delivery Date must be 2021-06-14.');
        }
        for (MVN_Payer_Plan__c payerPlan : payerPlans) {
            System.assertEquals('Abbott EGWP', payerPlan.Name, 'Name must be Abbott EGWP.');
            System.assertNotEquals(null, payerPlan.MVN_Precision_Id__c, 'Payer Plan must have an external id');
            System.assertNotEquals(null, payerPlan.MVN_Payer_Precision_Id__c, 'Payer Plan must have an external id for Payer.');
            System.assertNotEquals(null, payerPlan.MVN_Payer__c, 'Payer Plan must have a Payer.');
            System.assertNotEquals(null, payerPlan.MVN_Payer__r.MVN_Precision_Id__c, 'Payer Plan must have an external id for Payer.');
            System.assertEquals('Medicare Advantage', payerPlan.MVN_Medical_Channel__c, 'Medical Channel must be Medicare Advantage.');
            System.assertEquals('Medicare Part D', payerPlan.MVN_Pharmacy_Channel__c, 'Pharmacy Channel must be Medicare Part D.');
            System.assertEquals('EGWP', payerPlan.MVN_Channel_Detail__c, 'Channel Detail must be EGWP.');
        }
    }

    private static List<Account> getPayers() {
        return [
            SELECT
                Id,
                Name,
                MVN_Precision_Id__c,
                MVN_Payer_Channel_Precision_Id__c,
                MVN_Payer_Channel_Name__c,
                MVN_SRC_Data_Month__c,
                MVN_PX_Data_Month__c,
                MVN_PX_Delivery_Date__c
            FROM
                Account
            WHERE
                RecordType.DeveloperName = 'IndustriesPayer'
        ];
    }

    private static List<MVN_Payer_Plan__c> getPayerPlans() {
        return [
            SELECT
                Id,
                Name,
                MVN_Precision_Id__c,
                MVN_Payer_Precision_Id__c,
                MVN_Payer__c,
                MVN_Payer__r.MVN_Precision_Id__c,
                MVN_Medical_Channel__c,
                MVN_Pharmacy_Channel__c,
                MVN_Channel_Detail__c,
                MVN_PBM_Precision_Id__c,
                MVN_Medical_PBM_Processor__c,
                MVN_Pharmacy_PBM__c,
                MVN_Pharmacy_PBM_Relationship__c,
                MVN_SRC_Data_Month__c,
                MVN_PX_Date_Month__c,
                MVN_PX_Delivery_Date__c
            FROM
                MVN_Payer_Plan__c
            WHERE
                MVN_Payer__c != null
        ];
    }
}