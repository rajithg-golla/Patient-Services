/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingLabelQuery
 */
@isTest(isParallel=true) private class PJN_MappingLabelQueryTest {
    @isTest private static void queryByMapping() {
        PJN_MappingLabelQuery mappingLabelQuery = new PJN_MappingLabelQuery();

        Test.startTest();
            List<PJN_Mapping_Label__mdt> labelMappings = mappingLabelQuery.queryByMapping(new PJN_Mapping__mdt());
        Test.stopTest();

        System.assertEquals(0, labelMappings.size(), 'Incorrect empty query');
    }
}