/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_QueueQuery
 */
@isTest(isParallel=true) private class PJN_QueueQueryTest {
    @isTest private static void queryByDeveloperName() {
        PJN_QueueQuery queueQuery = new PJN_QueueQuery();

        Test.startTest();
            try {
                queueQuery.queryByDeveloperName('PJN_DOES_NOT_EXIST');
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage(), 'Incorrect query error thrown...');
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }
}