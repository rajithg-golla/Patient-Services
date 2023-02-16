/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingQuery
 */
@isTest(isParallel=true) private class PJN_MappingQueryTest {
    @isTest private static void queryMappingsByJobName() {
        PJN_MappingQuery mappingQuery = new PJN_MappingQuery();

        Test.startTest();
            List<PJN_Mapping__mdt> mappings = mappingQuery.queryMappingsByJobName('PJN_Does_Not_Exist');
        Test.stopTest();

        System.assertEquals(0, mappings.size(), 'Incorrect empty query');
    }
}