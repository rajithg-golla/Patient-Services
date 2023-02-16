/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingFieldQuery
 */
@isTest(isParallel=true) private class PJN_MappingFieldQueryTest {
    @isTest private static void queryByMapping() {
        PJN_MappingFieldQuery mappingFieldQuery = new PJN_MappingFieldQuery();

        Test.startTest();
            List<PJN_Mapping_Field__mdt> fieldMappings = mappingFieldQuery.queryByMapping(new PJN_Mapping__mdt());
        Test.stopTest();

        System.assertEquals(0, fieldMappings.size(), 'Incorrect empty query');
    }
}