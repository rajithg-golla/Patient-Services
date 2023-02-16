/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingQueueQuery
 */
@isTest(isParallel=true) private class PJN_MappingQueueQueryTest {
    @isTest private static void queryByMapping() {
        PJN_MappingQueueQuery mappingQueueQuery = new PJN_MappingQueueQuery();

        Test.startTest();
            try {
                mappingQueueQuery.queryByMapping(new PJN_Mapping__mdt());
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage(), 'Incorrect query error thrown...');
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }
}