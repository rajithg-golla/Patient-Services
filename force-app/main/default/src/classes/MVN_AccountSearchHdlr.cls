/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Account Search Handler to identify Patient and Consumer
 *              All Account Search Functionalities are in PJN_AccountSearchHdlr
 */
public with sharing class MVN_AccountSearchHdlr implements PJN_AccountSearchIntf {

    public List<PJN_AccountSearchRslt> search(PJN_AccountSearchRqst req) {

        // if the requests is for patient or consumer then search across both patient and consumer rec types
        Map<String, RecordTypeInfo> acctRecTypes = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id reqRecordTypeId = req.account.RecordTypeId;
        Boolean isPatientRecType = reqRecordTypeId == acctRecTypes.get('PJN_Patient').getRecordTypeId();
        Boolean isConsumerRecType = reqRecordTypeId == acctRecTypes.get('MVN_Consumer').getRecordTypeId();

        if (isPatientRecType || isConsumerRecType) {
            req.accountRecordTypeNames = new List<String>{ 'PJN_Patient', 'MVN_Consumer' };
        }

        List<PJN_AccountSearchRslt> results = new PJN_AccountSearchHdlr().search(req);
        for (PJN_AccountSearchRslt result : results) {
            result.searchUtilityClass = 'MVN_AccountSearchHdlr';
        }
        return results;
    }

    /**
    * Insert a record into the database.
    * @param searchResult  Account Search Result
    * @return `Id`         Account Search Result id
    */
    public Id insertAccountDetails(PJN_AccountSearchRslt searchResult) {
        // pass along to PJN_AccountSearchHdlr to handle
        return new PJN_AccountSearchHdlr().insertAccountDetails(searchResult);
    }

    /**
     * Given a searchRequest return results with all information needed to insert into database
     * @param searchRequest                     Account Search Request
     * @return `List<PJN_AccountSearchRslt>`    List of Account Search Results
     */
    public List<PJN_AccountSearchRslt> getAccountsWithDetails(PJN_AccountSearchRqst searchRequest) {
        // pass along to PJN_AccountSearchHdlr to handle
        return new PJN_AccountSearchHdlr().getAccountsWithDetails(searchRequest);
    }
}