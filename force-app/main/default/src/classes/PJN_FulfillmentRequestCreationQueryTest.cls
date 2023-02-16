/**
 * @author      Mavens
 * @group       Fulfillment
 * @description Unit tests for PJN_FulfillmentRequestCreationQuery
 */
@isTest(isParallel=true) public with sharing class PJN_FulfillmentRequestCreationQueryTest {
    @isTest private static void queryByProgramDeveloperNameAndRecordTypeDeveloperName() {
        PJN_FulfillmentRequestCreationQuery fulfillmentRequestCreationQuery = new PJN_FulfillmentRequestCreationQuery();

        Test.startTest();
            List<PJN_Fulfillment_Request_Creation__mdt> actualFulfillmentRequestCreations = fulfillmentRequestCreationQuery.queryByProgramDeveloperNameAndRecordTypeDeveloperName('PJN_Does_Not_Exist', 'PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, actualFulfillmentRequestCreations.size());
    }
}