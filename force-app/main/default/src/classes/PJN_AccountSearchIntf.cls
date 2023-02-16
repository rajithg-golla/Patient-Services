/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Interface describing an implementation of an account search handler
 */
public interface PJN_AccountSearchIntf {

    // Given a search request return a list of account search results
    List<PJN_AccountSearchRslt> search(PJN_AccountSearchRqst searchRequest);

    // Insert a record into the database
    Id insertAccountDetails(PJN_AccountSearchRslt searchResult);

    // Given a searchRequest return results with all information needed to insert into database
    List<PJN_AccountSearchRslt> getAccountsWithDetails(PJN_AccountSearchRqst searchRequest);
}