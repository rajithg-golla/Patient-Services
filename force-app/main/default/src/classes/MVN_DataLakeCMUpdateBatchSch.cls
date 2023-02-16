/**
 * @author      Mavens
 * @group       DataLake
 * @description Schedule the batch job to update all the allowed accounts with DataLake
 */
public with sharing class MVN_DataLakeCMUpdateBatchSch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    /**
     * Record Types allowed to be updated by DataLake
     */
    @TestVisible
    private static final Set<String> RECORD_TYPES_ALLOWED = new Set<String> {
        'PJN_Physician',
        'PJN_Staff',
        'PJN_Organization'
    };

    /**
     * Schedule Batch Job execute method
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        MVN_DataLakeCMUpdateBatchSch cmUpdateBatch = new MVN_DataLakeCMUpdateBatchSch();
        ID batchprocessid = Database.executeBatch(cmUpdateBatch, 100);
    }

    /**
     * Start batch job querying all accounts allowed to be updated
     * @param BC    Batch Context
     * @return  `Database.QueryLocator`
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    HealthCloudGA__SourceSystemId__c,
                    Name,
                    FirstName,
                    LastName,
                    MiddleName,
                    Salutation,
                    PersonTitle,
                    MVN_Birthdate__c,
                    PJN_NPI__c,
                    PJN_DEA__c,
                    PJN_Status__c,
                    IsPersonAccount
                FROM
                    Account
                WHERE
                    HealthCloudGA__SourceSystemId__c != null
                AND
                    RecordType.DeveloperName IN :RECORD_TYPES_ALLOWED
            ]
        );
    }

    /**
     * Execute batch job searching HCPs and HCOs in DataLake using the accounts allowed.
     * Upload those accounts found on DataLake
     * @param BC    Batch Context
     * @param scope Accounts allowed to be updated
     */
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Map<String, Account> hcpByExtId = new Map<String, Account>();
        Map<String, Account> hcoByExtId = new Map<String, Account>();
        for (Account thisAccount : scope) {
            if (thisAccount.isPersonAccount) {
                hcpByExtId.put(thisAccount.HealthCloudGA__SourceSystemId__c, thisAccount);
            } else {
                hcoByExtId.put(thisAccount.HealthCloudGA__SourceSystemId__c, thisAccount);
            }
        }
        List<Account> accountsToUpdate = new List<Account>();
        accountsToUpdate.addAll(getDataLakeAccounts(true, hcpByExtId));
        accountsToUpdate.addAll(getDataLakeAccounts(false, hcoByExtId));
        update accountsToUpdate;
    }

    /**
     * Get the Accounts with DataLake info to be updated
     * @param isPersonAccount   Defines if HCP or HCO search update
     * @param accountByExtId    Map of Accounts by External Id
     * @return  `List<Account>`
     */
    private static List<Account> getDataLakeAccounts(Boolean isPersonAccount, Map<String, Account> accountByExtId) {
        List<Account> accountsToUpdate = new List<Account>();
        String cmSearchQuery = getDataLakeAccountQuery(isPersonAccount, accountByExtId.keySet());
        for (Object datalakeAccount : MVN_DataLakeCMSearchAccount.searchAccounts(cmSearchQuery)) {
            String dataLakeAccountJSON = System.JSON.serialize(dataLakeAccount);
            Account accountToUpdate;
            if (isPersonAccount) {
                MVN_DataLakeCMHCP hcp = (MVN_DataLakeCMHCP) System.JSON.deserialize(dataLakeAccountJSON, MVN_DataLakeCMHCP.class);
                accountToUpdate = hcp.getSFDCRecord();
            } else {
                MVN_DataLakeCMHCO hco = (MVN_DataLakeCMHCO) System.JSON.deserialize(dataLakeAccountJSON, MVN_DataLakeCMHCO.class);
                accountToUpdate = hco.getSFDCRecord();
            }
            if (accountToUpdate.HealthCloudGA__SourceSystemId__c == null || !accountByExtId.containsKey(accountToUpdate.HealthCloudGA__SourceSystemId__c)) {
                continue;
            }
            accountToUpdate.Id = accountByExtId.get(accountToUpdate.HealthCloudGA__SourceSystemId__c).Id;
            accountsToUpdate.add(accountToUpdate);
        }
        return accountsToUpdate;
    }

    /**
     * Get DataLake Account Query depending on HCP or HCO Search
     * @param isPersonAccount   Defines if HCP or HCO Search
     * @param accExtIds         List of Account External Ids
     * @return  `String`
     */
    private static String getDataLakeAccountQuery(Boolean isPersonAccount, Set<String> accExtIds) {
        String query = 'SELECT * from ' + MVN_DataLakeCMSearchUtil.DATALAKE_ENVIRONMENT;
        query += isPersonAccount ? 'data_semarchy_cm_pub_m_hcp_profile' : 'data_semarchy_cm_pub_m_hco_profile';
        String accountIdFieldFilter = isPersonAccount ? 'hcp_id' : 'hco_id';
        query += ' WHERE ' + accountIdFieldFilter + ' in (';
        for (String accExtId : accExtIds) {
            query += accExtId + ',';
        }
        return query.substringBeforeLast(',') + ')';
    }

    /**
     * Finish batch job method
     * @param BC    Batch Context
     */
    public void finish(Database.BatchableContext BC) {
        PJN_PublishTransactionLog.publish();
    }
}