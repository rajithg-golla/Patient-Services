/**
 * @author      Mavens
 * @group       DataLake
 * @description Test for MVN_DataLakeCMSearchHdlr
 */
@IsTest
private class MVN_DataLakeCMSearchHdlrTest {

    static {

    }

    @TestSetup
    static void makeData(){
        Test.startTest();
        List<Account> accounts = new List<Account>();
        accounts.add(buildHCP());
        accounts.add(buildHCO());
        insert accounts;
        Test.stopTest();
    }

    private static Account buildHCP() {
        return new Account (
            HealthCloudGA__SourceSystemId__c = '12345678902',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            FirstName = 'May',
            LastName = 'Venn'
        );
    }

    private static Account buildHCO() {
        return new Account (
            HealthCloudGA__SourceSystemId__c = '12345678901',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId(),
            Name = 'Test HCO for Affiliation'
        );
    }

    @IsTest
    static void testIfSearchHCPCorrectlyWithResults() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakeCMSearchMock.SearchSuccessMock());
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Smith'
        );
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            PJN_City__c = 'Chicago'
        );
        PJN_AccountSearchRqst req = buildAccountSearchRequest(true, acc, contactInfo);
        List<PJN_AccountSearchRslt> searchRslts;
        Test.startTest();
        MVN_DataLakeCMSearchHdlr handler = new MVN_DataLakeCMSearchHdlr();
        searchRslts = handler.search(req);
        Test.stopTest();
        System.assertNotEquals(null, searchRslts, 'Results cannot be null.');
        System.assert(!searchRslts.isEmpty(), 'It must have results.');
        for (PJN_AccountSearchRslt searchRslt : searchRslts) {
            System.assertNotEquals(null, searchRslt.accountDetail, 'It must have an account');
            System.assertEquals('JOHN', searchRslt.accountDetail.FirstName, 'FirstName must be John');
            System.assertEquals('SMITH', searchRslt.accountDetail.LastName, 'LastName must be Smith');
        }
    }

    @IsTest
    static void testIfSearchHCPCorrectlyWithResultsAndInsert() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakeCMSearchMock.SearchSuccessMock());
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Smith'
        );
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            PJN_City__c = 'Chicago'
        );
        PJN_AccountSearchRqst req = buildAccountSearchRequest(true, acc, contactInfo);
        MVN_DataLakeCMSearchHdlr handler = new MVN_DataLakeCMSearchHdlr();
        List<PJN_AccountSearchRslt> searchRslts = handler.search(req);
        System.assertNotEquals(null, searchRslts, 'Results cannot be null.');
        System.assert(!searchRslts.isEmpty(), 'It must have results.');
        for (PJN_AccountSearchRslt searchRslt : searchRslts) {
            System.assertNotEquals(null, searchRslt.accountDetail, 'It must have an account');
            System.assertEquals('JOHN', searchRslt.accountDetail.FirstName, 'FirstName must be John');
            System.assertEquals('SMITH', searchRslt.accountDetail.LastName, 'LastName must be Smith');
        }
        Id accountId;
        Test.startTest();
        accountId = handler.insertAccountDetails(searchRslts[0]);
        Test.stopTest();
        System.assertNotEquals(null, accountId, 'Account has not been inserted.');
    }

    @IsTest
    static void testIfSearchHCOCorrectlyWithResults() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakeCMSearchMock.SearchSuccessMock());
        Account acc = new Account(
            Name = 'MAVENS HEALTH CLINIC'
        );
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            PJN_Country__c = 'United States'
        );
        PJN_AccountSearchRqst req = buildAccountSearchRequest(false, acc, contactInfo);
        List<PJN_AccountSearchRslt> searchRslts;
        Test.startTest();
        MVN_DataLakeCMSearchHdlr handler = new MVN_DataLakeCMSearchHdlr();
        searchRslts = handler.search(req);
        Test.stopTest();
        System.assertNotEquals(null, searchRslts, 'Results cannot be null.');
        System.assert(!searchRslts.isEmpty(), 'It must have results.');
        for (PJN_AccountSearchRslt searchRslt : searchRslts) {
            System.assertNotEquals(null, searchRslt.accountDetail, 'It must have an account');
            System.assertEquals('MAVENS HEALTH CLINIC', searchRslt.accountDetail.Name, 'Name must be MAVENS HEALTH CLINIC');
        }
    }

    @IsTest
    static void testIfSearchHCOCorrectlyWithResultsAndInsert() {
        Test.setMock(HttpCalloutMock.class, new MVN_DataLakeCMSearchMock.SearchSuccessMock());
        Account acc = new Account(
            Name = 'MAVENS HEALTH CLINIC'
        );
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            PJN_Country__c = 'United States'
        );
        PJN_AccountSearchRqst req = buildAccountSearchRequest(false, acc, contactInfo);
        MVN_DataLakeCMSearchHdlr handler = new MVN_DataLakeCMSearchHdlr();
        List<PJN_AccountSearchRslt> searchRslts = handler.search(req);
        System.assertNotEquals(null, searchRslts, 'Results cannot be null.');
        System.assert(!searchRslts.isEmpty(), 'It must have results.');
        for (PJN_AccountSearchRslt searchRslt : searchRslts) {
            System.assertNotEquals(null, searchRslt.accountDetail, 'It must have an account');
            System.assertEquals('MAVENS HEALTH CLINIC', searchRslt.accountDetail.Name, 'Name must be MAVENS HEALTH CLINIC');
        }
        Id accountId;
        Test.startTest();
        accountId = handler.insertAccountDetails(searchRslts[0]);
        Test.stopTest();
        System.assertNotEquals(null, accountId, 'Account has not been inserted.');
    }

    private static PJN_AccountSearchRqst buildAccountSearchRequest(Boolean isPersonSearch, Account acc, PJN_Contact_Information__c contactInfo) {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.isPersonSearch = isPersonSearch;
        req.account = acc;
        req.contactInfo = contactInfo;
        return req;
    }
}