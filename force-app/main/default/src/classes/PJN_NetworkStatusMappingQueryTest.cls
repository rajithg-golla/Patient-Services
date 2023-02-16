/**
 * Test for PJN_NetworkStatusMappingQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkStatusMappingQueryTest {

    @IsTest
    static void testQueryNetworkStatusMappings() {
        List<PJN_Network_Status_Mapping__mdt> networkStatusMappings;

        Test.startTest();
        PJN_NetworkStatusMappingQuery networkStatusMappingQuery = new PJN_NetworkStatusMappingQuery();
        networkStatusMappings = networkStatusMappingQuery.queryAll();
        Test.stopTest();

        System.assert(networkStatusMappings != null, 'Network status mappings cannot be null.');
    }
}