/**
 * Test PJN_NetworkRecordTypeMappingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkRecordTypeMappingsQueryTest {

    @IsTest
    static void testQueryNetworkRecordTypeMappings() {
        List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings;

        Test.startTest();
        PJN_NetworkRecordTypeMappingsQuery networkRecordTypeMappingsQuery = new PJN_NetworkRecordTypeMappingsQuery();
        networkRecordTypeMappings = networkRecordTypeMappingsQuery.queryAll();
        Test.stopTest();

        System.assert(networkRecordTypeMappings != null, 'Network record type mappings cannot be null.');
    }
}