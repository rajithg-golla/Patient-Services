/**
 * @author      Mavens
 * @group       DataLake
 * @description Handler to search in Datalake
 */
public with sharing class MVN_DataLakeCMSearchHdlr implements PJN_AccountSearchIntf {

    /**
     * Defines if HCP or HCO Search
     */
    private static Boolean isPersonSearch;

    /**
     * Search Record Type Id
     */
    private static String  recordTypeId;

    /**
     * Search Record Type Developer Name
     */
    private static String recordTypeInfoDevName;

    /**
     * Map of DataLake Addresses by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMAddress>> addressesByAccId;

    /**
     * Map of DataLake Emails by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMEmail>> emailsByAccId;

    /**
     * Map of DataLake Specialties by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMSpecialty>> specialtyByAccId;

    /**
     * Map of DataLake Phones by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMPhone>> phoneByAccId;

    /**
     * Map of DataLake Licenses by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMLicense>> licenseByAccId;

    /**
     * Map of DataLake Affiliations by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMAffiliation>> affiliationByAccId;

    /**
     * Map of DataLake HCO Affiliations by DataLake Account Id
     */
    private static Map<String, List<MVN_DataLakeCMHCOAffiliation>> hcoAffiliationByAccId;

    /**
     * Verify some filter is being populated
     */
    public static Boolean hasSearchFilter = false;

    /**
     * Allowed Record Types
     */
    private static final Set<String> SEARCH_ACCOUNT_RECORD_TYPES_ALLOWED = new Set<String> {
        'PJN_Physician',
        'PJN_Staff',
        'PJN_Organization',
        '',
        null
    };

    /**
     * Account Search Query Fields
     */
    private static List<PJN_FieldWrapper> queryFields {
        get {
            if (queryFields == null) {
                String search = isPersonSearch ? 'Person_Search_Query' : 'Business_Search_Query';
                queryFields = PJN_AccountSearchLightningUtil.getFields(search, recordTypeId);
            }
            return queryFields;
        }
        set;
    }

    /**
     * Search in DataLake to retrieve results and restructure this into SFDC structure
     * The search will only allow certain record types and ALL type
     * @param req   Account Search Request
     * @return  `List<PJN_AccountSearchRslt>`
     */
    public List<PJN_AccountSearchRslt> search(PJN_AccountSearchRqst req) {
        isPersonSearch = req.isPersonSearch;
        recordTypeId = req.account.RecordTypeId;
        recordTypeInfoDevName = String.isNotBlank(recordTypeId) ?
            Account.getSObjectType().getDescribe().getRecordTypeInfosById().get(recordTypeId).getDeveloperName() :
            null;

        if (!SEARCH_ACCOUNT_RECORD_TYPES_ALLOWED.contains(recordTypeInfoDevName)) {
            return new List<PJN_AccountSearchRslt>();
        }
        System.debug((isPersonSearch ? 'Person' : 'Business') + ' search for ' + recordTypeId);
        String cmSearchQuery = getSearchQuery(req);
        System.debug('### DataLake::CM::Search::Account Query: \n\n' + cmSearchQuery);
        List<PJN_AccountSearchRslt> finalResults = new List<PJN_AccountSearchRslt>();
        if (hasSearchFilter) {
            List<Object> dataLakeAccounts = getDataLakeAccountsAndChildren(cmSearchQuery);
            finalResults = getFinalResults(dataLakeAccounts);
        }
        System.debug('### DataLake::CM::Search::finalResults size: ' + finalResults.size());
        System.debug('### DataLake::CM::Search::finalResults: ' + finalResults);
        PJN_PublishTransactionLog.publish();
        return finalResults;
    }

    /**
     *
     * @return  `String`
     */
    /**
     * Get Account Search Query including Email/Address filters
     * @param req   Account Search Request
     * @return  `String`
     */
    private static String getSearchQuery(PJN_AccountSearchRqst req) {
        if (isPersonSearch) {
            MVN_DataLakeCMSearchAccount.searchHCP = new MVN_DataLakeCMHCP(getNonNulls(req.account.getPopulatedFieldsAsMap()));
            MVN_DataLakeCMSearchEmail.searchEmail = new MVN_DataLakeCMEmail(getNonNulls(req.contactInfo.getPopulatedFieldsAsMap()));
        } else {
            MVN_DataLakeCMSearchAccount.searchHCO = new MVN_DataLakeCMHCO(getNonNulls(req.account.getPopulatedFieldsAsMap()));
        }
        MVN_DataLakeCMSearchAddress.searchAddress = new MVN_DataLakeCMAddress(getNonNulls(req.contactInfo.getPopulatedFieldsAsMap()));
        String query = MVN_DataLakeCMSearchAccount.getAccountSearchQuery(isPersonSearch);
        String additionalFilters = getContactInformationSearchQuery();
        if (String.isNotBlank(additionalFilters)) {
            query += ' AND ' + additionalFilters;
        }
        if (MVN_DataLakeCMSearchUtil.DATALAKE_SEARCH_LIMIT != null && MVN_DataLakeCMSearchUtil.DATALAKE_SEARCH_LIMIT > 0) {
            query += ' LIMIT ' + MVN_DataLakeCMSearchUtil.DATALAKE_SEARCH_LIMIT;
        }
        return query;
    }

    /**
     * Get Non Nulls values populated in the Account Search Request
     * @param populatedFields   Object populated fields
     * @return  `Map<String, Object>`
     */
    private static Map<String, Object> getNonNulls(Map<String, Object> populatedFields) {
        Map<String, Object> nonNulls = new Map<String, Object>();
        System.debug(populatedFields);
        for (String field : populatedFields.keySet()) {
            if (populatedFields.get(field) != null) {
                //TODO: Determine if this test is valid across all types
                if (String.isNotBlank(String.valueOf(populatedFields.get(field)))) {
                    nonNulls.put(field.toLowerCase(), populatedFields.get(field));
                }
            }
        }
        return nonNulls;
    }

    /**
     * Get Contact Information Search query to filter Account in the search
     * @return  `String`
     */
    private static String getContactInformationSearchQuery() {
        String additionalFilters = '';
        additionalFilters += MVN_DataLakeCMSearchAddress.getAccountFilter(isPersonSearch);
        additionalFilters += MVN_DataLakeCMSearchEmail.getAccountFilter(isPersonSearch);
        if (String.isNotBlank(additionalFilters)) {
            additionalFilters = '(' + additionalFilters.substringBeforeLast(' OR ') + ')';
        }
        return additionalFilters;
    }

    /**
     * Call all the DataLake tables to obtain the required objects to show in our Account Search
     * @param cmSearchQuery Customer Master Search Query
     * @return  `List<Object>`
     */
    private static List<Object> getDataLakeAccountsAndChildren(String cmSearchQuery) {
        List<Object> dataLakeAccounts = MVN_DataLakeCMSearchAccount.searchAccounts(cmSearchQuery);
        Set<String> dataLakeAccountIds = MVN_DataLakeCMSearchAccount.getAccountIds(isPersonSearch, dataLakeAccounts);
        addressesByAccId = MVN_DataLakeCMSearchAddress.searchAddresses(isPersonSearch, dataLakeAccountIds);
        emailsByAccId = MVN_DataLakeCMSearchEmail.searchEmails(isPersonSearch, dataLakeAccountIds);
        specialtyByAccId = MVN_DataLakeCMSearchSpecialty.searchSpecialties(isPersonSearch, dataLakeAccountIds);
        phoneByAccId = MVN_DataLakeCMSearchPhone.searchPhones(isPersonSearch, dataLakeAccountIds);
        licenseByAccId = MVN_DataLakeCMSearchLicense.searchLicenses(isPersonSearch, dataLakeAccountIds);
        affiliationByAccId = MVN_DataLakeCMSearchAffiliation.searchAffiliations(isPersonSearch, dataLakeAccountIds);
        hcoAffiliationByAccId = MVN_DataLakeCMSearchHCOAffiliation.searchHCOAffiliations(isPersonSearch, dataLakeAccountIds);
        return dataLakeAccounts;
    }

    /**
     * Insert a record into the database
     * @param searchResult  DataLake record
     * @return  `Id`
     */
    public Id insertAccountDetails(PJN_AccountSearchRslt searchResult) {
        try {
            insert searchResult.accountDetail;
            upsertContactInformations(searchResult);
            isPersonSearch = [SELECT isPersonAccount FROM Account WHERE Id = :searchResult.accountDetail.Id].isPersonAccount;
            upsertLicenses(searchResult);
            upsertAffiliations(searchResult);
            return searchResult.accountDetail.Id;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Upsert Contact Informations related to an account using external id
     * @param searchResult  DataLake record
     */
    private static void upsertContactInformations(PJN_AccountSearchRslt searchResult) {
        if (searchResult.contactInfoByNetworkId != null) {
            for (PJN_Contact_Information__c ci : searchResult.contactInfoByNetworkId.values()) {
                ci.PJN_Account__c = searchResult.accountDetail.Id;
            }
            upsert searchResult.contactInfoByNetworkId.values() PJN_External_Id__c;
        }
    }

    /**
     * Upsert Licenses related to an account using external id
     * @param searchResult  DataLake record
     */
    private static void upsertLicenses(PJN_AccountSearchRslt searchResult) {
        if (searchResult.licensesByNetworkId != null) {
            for (PJN_License__c license : searchResult.licensesByNetworkId.values()) {
                license.PJN_Account__c = searchResult.accountDetail.Id;
                if (license.PJN_Contact_Information__c != null && searchResult.contactInfoByNetworkId != null && searchResult.contactInfoByNetworkId.containsKey(license.PJN_Contact_Information__c)) {
                    license.PJN_Contact_Information__c = ((PJN_Contact_Information__c) searchResult.contactInfoByNetworkId.get(license.PJN_Contact_Information__c)).Id;
                } else if (license.PJN_Contact_Information__c != null) {
                    license.PJN_Contact_Information__c = null;
                }
            }
            upsert searchResult.licensesByNetworkId.values() MVN_External_Id__c;
        }
    }

    /**
     * Upsert Affiliations related to an account using external id
     * @param searchResult  DataLake record
     */
    private static void upsertAffiliations(PJN_AccountSearchRslt searchResult) {
        if (searchResult.affiliationsByNetworkId != null) {
            Set<String> accountExtIds = new Set<String>();
            for (PJN_Affiliation__c affiliation : searchResult.affiliationsByNetworkId.values()) {
                accountExtIds.add(affiliation.PJN_Parent_Account__r.HealthCloudGA__SourceSystemId__c);
                if (!isPersonSearch) {
                    accountExtIds.add(affiliation.PJN_Child_Account__r.HealthCloudGA__SourceSystemId__c);
                }
            }
            Set<String> existingAccountExtIds = getExistingAccountExtIds(accountExtIds);
            List<PJN_Affiliation__c> affiliations = new List<PJN_Affiliation__c>();
            for (PJN_Affiliation__c affiliation : searchResult.affiliationsByNetworkId.values()) {
                Boolean hasExistingRelation = (isPersonSearch && existingAccountExtIds.contains(affiliation.PJN_Parent_Account__r.HealthCloudGA__SourceSystemId__c))
                    || (!isPersonSearch && existingAccountExtIds.contains(affiliation.PJN_Child_Account__r.HealthCloudGA__SourceSystemId__c) && existingAccountExtIds.add(affiliation.PJN_Parent_Account__r.HealthCloudGA__SourceSystemId__c));
                if (hasExistingRelation) {
                    affiliations.add(affiliation);
                }
            }
            upsert affiliations MVN_External_Id__c;
        }
    }

    /**
     * Get Existing Accounts related to the Affiliations using Source System Ids
     * @param accountExtIds Account Source System Ids
     * @return  `Set<String>`
     */
    private static Set<String> getExistingAccountExtIds(Set<String> accountExtIds) {
        Set<String> existingAccountExtIds = new Set<String>();
        for (Account thisAccount : [
            SELECT
                Id,
                HealthCloudGA__SourceSystemId__c
            FROM
                Account
            WHERE
                HealthCloudGA__SourceSystemId__c IN :accountExtIds
        ]) {
            existingAccountExtIds.add(thisAccount.HealthCloudGA__SourceSystemId__c);
        }
        return existingAccountExtIds;
    }

    /**
     * Given a searchRequest return results with all information needed to insert into database
     * @param searchRequest Account Search Request
     * @return  `List<PJN_AccountSearchRslt>`
     */
    public List<PJN_AccountSearchRslt> getAccountsWithDetails(PJN_AccountSearchRqst searchRequest) {
        //TODO: implement
        return new List<PJN_AccountSearchRslt>();
    }

    /**
     * Get Final and SFDC structured results from DataLake
     * @param dataLakeAccounts  List of DataLake Accounts
     * @return  `List<PJN_AccountSearchRslt>`
     */
    private static List<PJN_AccountSearchRslt> getFinalResults(List<Object> dataLakeAccounts) {
        List<PJN_AccountSearchRslt> results = new List<PJN_AccountSearchRslt>();
        List<Account> accounts = getSFDCAccountRecords(dataLakeAccounts);
        for (Account thisAccount : accounts) {
            if (specialtyByAccId.containsKey(thisAccount.HealthCloudGA__SourceSystemId__c)) {
                List<MVN_DataLakeCMSpecialty> specialties = specialtyByAccId.get(thisAccount.HealthCloudGA__SourceSystemId__c);
                thisAccount = specialties[0].getSFDCRecord(thisAccount);
            }
            PJN_AccountSearchRslt currentResult = new PJN_AccountSearchRslt (
                thisAccount,
                'MVN_DataLakeCMSearchHdlr',
                queryFields
            );
            List<PJN_Contact_Information__c> cis = getContactInformations(thisAccount.HealthCloudGA__SourceSystemId__c);
            if (!cis.isEmpty()) {
                currentResult.addContactInfoRecords(cis);
            }
            Map<String, PJN_License__c> licensesByExtId = getHCPLicenses(thisAccount.HealthCloudGA__SourceSystemId__c);
            if (!licensesByExtId.isEmpty()) {
                currentResult.addLicenses(licensesByExtId);
            }
            Map<String, PJN_Affiliation__c> affiliationsByExtId = getAffiliations(thisAccount.HealthCloudGA__SourceSystemId__c);
            if (!affiliationsByExtId.isEmpty()) {
                currentResult.addAffiliations(affiliationsByExtId);
            }
            results.add(currentResult);
        }
        return results;
    }

    /**
     * Get SFDC Account Records using DataLake Account records
     * @param datalakeAccounts  DataLake Account records
     * @return  `List<Account>`
     */
    private static List<Account> getSFDCAccountRecords(List<Object> datalakeAccounts) {
        List<Account> accounts = new List<Account>();
        Map<Id, RecordType> recordTypeById = getRecordTypeByDeveloperName();
        for (Object datalakeAccount : datalakeAccounts) {
            String dataLakeAccountJSON = System.JSON.serialize(dataLakeAccount);
            if (isPersonSearch) {
                MVN_DataLakeCMHCP hcp = (MVN_DataLakeCMHCP) System.JSON.deserialize(dataLakeAccountJSON, MVN_DataLakeCMHCP.class);
                Account hcpRecord = hcp.getSFDCRecord();
                RecordType currentRecordType = recordTypeById.get(hcpRecord.RecordTypeId);
                if (currentRecordType != null) {
                    hcpRecord.putSObject('RecordType', currentRecordType);
                }
                accounts.add(hcpRecord);
            } else {
                MVN_DataLakeCMHCO hco = (MVN_DataLakeCMHCO) System.JSON.deserialize(dataLakeAccountJSON, MVN_DataLakeCMHCO.class);
                Account hcoRecord = hco.getSFDCRecord();
                RecordType currentRecordType = recordTypeById.get(hcoRecord.RecordTypeId);
                if (currentRecordType != null) {
                    hcoRecord.putSObject('RecordType', currentRecordType);
                }
                accounts.add(hcoRecord);
            }
        }
        return accounts;
    }

    private static Map<Id, RecordType> getRecordTypeByDeveloperName() {
        return new Map<Id, RecordType>([
            SELECT
                Id,
                Name,
                DeveloperName
            FROM
                RecordType
            WHERE
                SobjectType = 'Account'
        ]);
    }

    /**
     * Get Contact Information records related to an account using the external id
     * This includes phones, faxes, addresses and emails
     * @param accountExternalId Account Source System Id
     * @return  `List<PJN_Contact_Information__c>`
     */
    private static List<PJN_Contact_Information__c> getContactInformations(String accountExternalId) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        if (addressesByAccId != null && addressesByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMAddress addr : addressesByAccId.get(accountExternalId)) {
                cis.add(addr.getSFDCRecord());
            }
        }
        if (emailsByAccId != null && emailsByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMEmail email : emailsByAccId.get(accountExternalId)) {
                cis.add(email.getSFDCRecord(isPersonSearch));
            }
        }
        if (phoneByAccId != null && phoneByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMPhone phone : phoneByAccId.get(accountExternalId)) {
                cis.add(phone.getSFDCRecord(isPersonSearch));
            }
        }
        return cis;
    }

    /**
     * Get HCP Licenses related to an account using external id
     * @param accountExternalId Account Source System Id
     * @return  `Map<String, PJN_License__c>`
     */
    private static Map<String, PJN_License__c> getHCPLicenses(String accountExternalId) {
        Map<String, PJN_License__c> hcpLicensesByExtId = new Map<String, PJN_License__c>();
        if (licenseByAccId != null && licenseByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMLicense license : licenseByAccId.get(accountExternalId)) {
                hcpLicensesByExtId.put(license.hcp_license_id, license.getSFDCRecord());
            }
        }
        return hcpLicensesByExtId;
    }

    /**
     * Get all affiliations related to an account using external id
     * @param accountExternalId Account Source System Id
     * @return  `Map<String, PJN_Affiliation__c>`
     */
    private static Map<String, PJN_Affiliation__c> getAffiliations(String accountExternalId) {
        Map<String, PJN_Affiliation__c> affiliationsByExtId = new Map<String, PJN_Affiliation__c>();
        Map<String, PJN_Affiliation__c> hcpHcoAffiliationsByExtId = getHcoHcpAffiliations(accountExternalId);
        if (!hcpHcoAffiliationsByExtId.isEmpty()) {
            affiliationsByExtId.putAll(hcpHcoAffiliationsByExtId);
        }
        Map<String, PJN_Affiliation__c> hcoHcoAffiliationsByExtId = getHcoHcoAffiliations(accountExternalId);
        if (!hcoHcoAffiliationsByExtId.isEmpty()) {
            affiliationsByExtId.putAll(hcoHcoAffiliationsByExtId);
        }
        return affiliationsByExtId;
    }

    /**
     * Get HCO to HCP Affiliations related to an account using external Id
     * @param accountExternalId Account Source System Id
     * @return  `Map<String, PJN_Affiliation__c>`
     */
    private static Map<String, PJN_Affiliation__c> getHcoHcpAffiliations(String accountExternalId) {
        Map<String, PJN_Affiliation__c> affiliationsByExtId = new Map<String, PJN_Affiliation__c>();
        if (affiliationByAccId != null && affiliationByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMAffiliation affiliation : affiliationByAccId.get(accountExternalId)) {
                affiliationsByExtId.put(affiliation.hco_hcp_affiliation_id, affiliation.getSFDCRecord());
            }
        }
        return affiliationsByExtId;
    }

    /**
     * Get HCO to HCO Affiliations related to an account using external Id
     * @param accountExternalId Account Source Sytem Id
     * @return  `Map<String, PJN_Affiliation__c>`
    */
    private static Map<String, PJN_Affiliation__c> getHcoHcoAffiliations(String accountExternalId) {
        Map<String, PJN_Affiliation__c> affiliationsByExtId = new Map<String, PJN_Affiliation__c>();
        if (hcoAffiliationByAccId != null && hcoAffiliationByAccId.containsKey(accountExternalId)) {
            for (MVN_DataLakeCMHCOAffiliation hcoAffiliation : hcoAffiliationByAccId.get(accountExternalId)) {
                affiliationsByExtId.put(hcoAffiliation.hco_hco_affiliation_id, hcoAffiliation.getSFDCRecord());
            }
        }
        return affiliationsByExtId;
    }
}