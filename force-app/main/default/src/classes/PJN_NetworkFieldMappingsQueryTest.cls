/**
 * Test PJN_NetworkFieldMappingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkFieldMappingsQueryTest {

    @IsTest
    static void testQueryNetworkFieldMappings() {
        List<PJN_Network_Field_Mapping__mdt> networkFieldMappings;

        Test.startTest();
        PJN_NetworkFieldMappingsQuery networkFieldMappingQuery = new PJN_NetworkFieldMappingsQuery();
        networkFieldMappings = networkFieldMappingQuery.queryAllWithValues();
        Test.stopTest();

        System.assert(networkFieldMappings != null, 'Network field mappings cannot be null.');
    }
}