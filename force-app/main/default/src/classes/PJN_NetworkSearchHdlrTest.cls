/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Test for PJN_NetworkSearchHdlr
 */
@isTest(isParallel=true)
private class PJN_NetworkSearchHdlrTest {

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
    }

    @isTest
    private static void itShouldPerformAHCPSearch() {
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkSearchHdlrMock.SearchSuccessMock());

        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account(LastName = 'Smith');
        req.contactInfo = new PJN_Contact_Information__c(PJN_Phone__c = '5556667777');
        req.isPersonSearch = true;
        req.maxResults = 50;

        PJN_NetworkSearchHdlr searchHdlr = new PJN_NetworkSearchHdlr();

        List<PJN_AccountSearchRslt> results;
        Test.startTest();
        PJN_NetworkCallout.noRunInTest = false;
        results = searchHdlr.search(req);
        Test.stopTest();
        System.assertEquals(10, results.size());
    }
}