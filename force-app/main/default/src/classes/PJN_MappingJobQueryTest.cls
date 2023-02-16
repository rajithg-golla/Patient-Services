/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_MappingJobQuery
 */
@isTest(isParallel=true) private class PJN_MappingJobQueryTest {
    @isTest private static void queryByJobName() {
        PJN_MappingJobQuery mappingJobQuery = new PJN_MappingJobQuery();

        Test.startTest();
            try {
                mappingJobQuery.queryByJobName('PJN_Does_Not_Exist');
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(System.QueryException queryEx) {
                System.assertEquals('List has no rows for assignment to SObject', queryEx.getMessage(), 'Incorrect query error thrown...');
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }
}