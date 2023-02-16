/**
 * Test PJN_NetworkObjectSettingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkObjectSettingsQueryTest {

    @IsTest
    static void testQueryDCRSObjectSetting() {
        List<PJN_Network_Object_Setting__mdt> networkObjectSetting;

        Test.startTest();
        PJN_NetworkObjectSettingsQuery networkObjectSettingsQuery = new PJN_NetworkObjectSettingsQuery();
        networkObjectSetting = networkObjectSettingsQuery.queryAll();
        Test.stopTest();

        System.assert(networkObjectSetting != null, 'Network object settings cannot be null.');
    }
}