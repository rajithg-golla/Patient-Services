/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingDateFormulaQuery
 */
@isTest(isParallel=true) private class PJN_MappingDateFormulaQueryTest {
    @isTest private static void queryByMapping() {
        PJN_MappingDateFormulaQuery mappingDateFormulaQuery = new PJN_MappingDateFormulaQuery();

        Test.startTest();
            List<PJN_Mapping_Date_Formula__mdt> dateFormulaMappings = mappingDateFormulaQuery.queryByMapping(new PJN_Mapping__mdt());
        Test.stopTest();

        System.assertEquals(0, dateFormulaMappings.size(), 'Incorrect empty query');
    }
}