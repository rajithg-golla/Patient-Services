/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingRecordTypeQuery
 */
@isTest(isParallel=true) private class PJN_MappingRecordTypeQueryTest {
    @isTest private static void queryByMapping() {
        PJN_MappingRecordTypeQuery mappingRecordTypeQuery = new PJN_MappingRecordTypeQuery();

        Test.startTest();
            try {
                mappingRecordTypeQuery.queryByMapping(new PJN_Mapping__mdt());
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage(), 'Incorrect query error thrown...');
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }
}