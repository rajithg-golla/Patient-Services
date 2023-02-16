/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Handler for the local account search. Search is accomplished by breaking inputs
 *              into various search types and performing multiple searches using the account ids
 *              found in any prior searches as filters for subsequent searches.
 */
public with sharing class PJN_AccountSearchHdlr implements PJN_AccountSearchIntf {

    /**
    * Search Types
    */
   private enum SearchOption { ACCOUNT, ADDRESS, EMAIL, PHONE, FAX }

   /**
    * Exception class
    */
   public class PJNSearchException extends Exception{}

   /**
    * CarePlan record type developer name for Case object
    */
   private static final String CAREPLAN_REC_TYPE = 'CarePlan';

    /**
    * Store the account records types being searched
    */
    private static List<String> accountSearchRecTypes = new List<String>();

   /**
    * Defines if current search is for Person or Business Account
    */
   private static Boolean isPersonSearch;
   private static String  recordTypeId;
   private static PJN_Global_Setting__mdt globalSetting = PJN_Utilities.globalSetting;

   /**
    * Map of search type to search wrapper
    */
   private static Map<SearchOption, SearchWrapper> searchMap;

   /**
    * Keeps track of current account ids. Used to filter searches after the first search
    */
   private static Set<Id> currentAccountIds;

   private static PJN_FieldWrapper acctStatusWrapper = new PJN_FieldWrapper(
       'Account',
       Account.PJN_Status__c.getDescribe()
   );
   private static PJN_FieldWrapper contactInfoStatusWrapper = new PJN_FieldWrapper(
       'PJN_Contact_Information__c',
       PJN_Contact_Information__c.PJN_Status__c.getDescribe()
   );

   /**
    * Hold list of searches performed. Used for unit testing the building of the strings
    */
   @TestVisible
   private static List<String> searchStrings;

   /**
    * Only Email, Phone, and String type fields are searchable with SOSL
    */
   private static Set<Schema.DisplayType> searchableTypes = new Set<Schema.DisplayType> {
       Schema.DisplayType.Email,
       Schema.DisplayType.Phone,
       Schema.DisplayType.String
   };

   @TestVisible
   private static Integer SEARCH_MAX = 2000;

   /**
    * Given a search request return a list of account search results
    * @param req                               Account Search Request
    * @return `List<PJN_AccountSearchRslt>`    List of Account Search Results
    */
   public List<PJN_AccountSearchRslt> search(PJN_AccountSearchRqst req) {

        recordTypeId = req.account.RecordTypeId;
        // Account record type id controls the fields that are searched but accountRecordTypeNames
        // controls the types that are searched. If no value is present for accountRecordTypeNames
        // then set it here.
        // This pattern allows a developer to write a custom handler that can search across more than
        // one record type. Example: Customer had separated cosunmers and patients by record type but
        // when the search was performed for patient they also wanted to see consumers. custom handler
        // can be used to set the accountRecordTypeNames values then pass to this class.
        if (req.account.RecordTypeId != null && req.accountRecordTypeNames == null) {
            req.accountRecordTypeNames = new List<String> {
                Account.getSObjectType()
                    .getDescribe()
                    .getRecordTypeInfosById()
                    .get(req.account.RecordTypeId)
                    .DeveloperName
            };
        }

        // if there are req.accountRecordTypeNames set them to the static variable accountSearchRecTypes
        // for use in individual searches
        if (req.accountRecordTypeNames != null) {
            accountSearchRecTypes = req.accountRecordTypeNames;
        }

        searchStrings = new List<String>();

        isPersonSearch = req.isPersonSearch;
        initializeFilters(req);

        // perform account search and short circuit execution if a search was
        // performed but no accounts were found
        searchMap.get(SearchOption.ACCOUNT).search(null);
        if (currentAccountIds != null && currentAccountIds.isEmpty()) {
            return new List<PJN_AccountSearchRslt>();
        }

        // perform each contact info search, passing in the account filters and short
        // circuit execution if a search was performed but no account ids were found.
        Map<PJN_FieldWrapper, Object> accountFilterMap = searchMap.get(SearchOption.ACCOUNT).filterMap;
        for (SearchOption searchType : new List<SearchOption> {SearchOption.ADDRESS, SearchOption.EMAIL, SearchOption.PHONE, SearchOption.FAX}){
            searchMap.get(searchType).search(accountFilterMap);
            if (currentAccountIds != null && currentAccountIds.isEmpty()) {
                return new List<PJN_AccountSearchRslt>();
            }
        }

        return getFinalResults();
   }

   /**
    * Given a search request set up the various searches
    * @param req   Account Search Request
    */
   private void initializeFilters(PJN_AccountSearchRqst req) {

       searchMap = new Map<SearchOption, SearchWrapper> {
           SearchOption.ACCOUNT => new SearchWrapper('Account', req.accountRecordTypeNames),
           SearchOption.ADDRESS => new SearchWrapper('PJN_Contact_Information__c', globalSetting.PJN_Contact_Info_Address_Record_Types__c),
           SearchOption.EMAIL => new SearchWrapper('PJN_Contact_Information__c', globalSetting.PJN_Contact_Info_Email_Record_Types__c),
           SearchOption.PHONE => new SearchWrapper('PJN_Contact_Information__c', globalSetting.PJN_Contact_Info_Phone_Record_Types__c),
           SearchOption.FAX => new SearchWrapper('PJN_Contact_Information__c', globalSetting.PJN_Contact_Info_Fax_Record_Types__c)
       };

       // from populated requests get all non null values
       Map<String, Object> acctFields = getNonNulls(req.account.getPopulatedFieldsAsMap());
       Map<String, Object> ciFields = getNonNulls(req.contactInfo.getPopulatedFieldsAsMap());

       for (PJN_FieldWrapper field : getSearchFields(req.account.RecordTypeId)) {
           if (field.objectName == 'Account' && acctFields.containsKey(field.fieldName)) {
               searchMap.get(SearchOption.ACCOUNT).addTerm(field, acctFields.get(field.fieldName));
           } else if (field.objectName == 'PJN_Contact_Information__c' && ciFields.containsKey(field.fieldName)) {
               SearchOption searchType = null;
               switch on field.setting.PJN_Contact_Info_Record_Type__c {
                   when 'PJN_Address' { searchType = SearchOption.ADDRESS; }
                   when 'PJN_Email'   { searchType = SearchOption.EMAIL; }
                   when 'PJN_Phone'   { searchType = SearchOption.PHONE; }
                   when 'PJN_Fax'     { searchType = SearchOption.FAX; }
               }
               if (searchType != null) {
                   searchMap.get(searchType).addTerm(field, ciFields.get(field.fieldName));
               }
           }
       }

       if (String.isNotBlank(globalSetting.PJN_Account_Search_Account_Status__c)) {
           searchMap.get(SearchOption.ACCOUNT).addTerm(
               acctStatusWrapper,
               globalSetting.PJN_Account_Search_Account_Status__c
           );
       }

       if (String.isNotBlank(globalSetting.PJN_Account_Search_Contact_Info_Status__c)) {
           for (SearchOption option : searchMap.keySet()) {
               if (option != SearchOption.ACCOUNT) {
                   searchMap.get(option).addTerm(
                       contactInfoStatusWrapper,
                       globalSetting.PJN_Account_Search_Contact_Info_Status__c
                   );
               }
           }
       }
   }

   /**
    * Get search filter fields populated with non null values
    * @param populatedFields           Map of filter values by filter field name
    * @return `Map<String, Object>`    Map of filter non null values by filter field name
    */
   private static Map<String, Object> getNonNulls(Map<String, Object> populatedFields) {
       Map<String, Object> nonNulls = new Map<String, Object>();
       for (String field : populatedFields.keySet()) {
           if (populatedFields.get(field) != null) {
               if (String.isNotBlank(String.valueOf(populatedFields.get(field)))) {
                   nonNulls.put(field, populatedFields.get(field));
               }
           }
       }
       return nonNulls;
   }


   /**
    * Insert a record into the database.
    * @param searchResult  Account Search Result
    * @return `Id`         Account Search Result id
    */
   public Id insertAccountDetails(PJN_AccountSearchRslt searchResult) {
       // This handler only has Salesforce results so no need to insert into database
       return searchResult.accountDetail.Id;
   }

   /**
    * Given a searchRequest return results with all information needed to insert into database
    * @param searchRequest                     Account Search Request
    * @return `List<PJN_AccountSearchRslt>`    List of Account Search Results
    */
   public List<PJN_AccountSearchRslt> getAccountsWithDetails(PJN_AccountSearchRqst searchRequest) {
       // This handler only has Salesforce results so no need to insert into database
       return new List<PJN_AccountSearchRslt>();
   }

   /**
    * Get all accounts queried using the accounts found using SOSL and Accounts related to Contact Infos found using SOSL
    * @param accounts                          List of Accounts found using SOSL
    * @param ciAccountIds                      Set of account Ids related to Contact Infos found using SOSL
    * @return `Map<Id, PJN_AccountSearchRslt>` Map of PJN_AccountSearchRslt by Account Id
    */
   private static List<PJN_AccountSearchRslt> getFinalResults() {
       List<PJN_AccountSearchRslt> results = new List<PJN_AccountSearchRslt>();

       if (currentAccountIds == null) {
           return results;
       }

       String contactInfoStatusFilter = getStatusFilter('PJN_Status__c', globalSetting.PJN_Account_Search_Contact_Info_Status__c);

       String qString = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(accountFields), ',')) +', '
                       +        '(SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(contactInfoFields), ','))
                       +        '   FROM PJN_Contact_Information__r '
                       +        '   WHERE IsDeleted=false ' + contactInfoStatusFilter
                       +        ' ORDER BY PJN_Primary__c DESC), '
                       +        '(SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(affiliationFields), ','))
                       +        '   FROM Affiliation__r), '
                       +        '(SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(carePlanFields), ','))
                       +        '   FROM Cases WHERE RecordType.DeveloperName = :CAREPLAN_REC_TYPE) '
                       + '  FROM Account '
                       + ' WHERE Id IN :currentAccountIds'
                       + ' AND isPersonAccount = :isPersonSearch';

       List<Account> finalAccounts = Database.query(qString);

       for (Account account : finalAccounts) {
           results.add(
               new PJN_AccountSearchRslt(account, 'PJN_AccountSearchHdlr', queryFields)
           );
       }

       return results;
   }

   /**
    * @description Given Status Field name and a list of statuses allowed return a where clause for Status filter
    * @param statusFieldName - Status Field name from object
    * @param statusesAllowed - Statuses allowed to pass the filter
    * @returns `String`
    */
   private static String getStatusFilter(String statusFieldName, String statusesAllowed) {
       String statusFilter = '';
       if (String.isNotBlank(statusesAllowed)) {
           List<String> statusAllowedList = statusesAllowed.split(',');
           statusFilter = ' AND ' + statusFieldName + ' IN (';
           for (String statusAllowed : statusAllowedList) {
               if (String.isNotBlank(statusAllowed)) {
                   statusFilter += '\'' + statusAllowed + '\',';
               }
           }
           statusFilter = statusFilter.substringBeforeLast(',') + ')';
       }
       return statusFilter;
   }

   /**
    * List of Field wrappers depending on Account Record type
    */
   private static List<PJN_FieldWrapper> getSearchFields(Id recordTypeId) {
       String search = isPersonSearch ? 'Person_Search_Form' : 'Business_Search_Form';
       List<PJN_FieldWrapper> searchFields = PJN_AccountSearchLightningUtil.getFields(search, recordTypeId);
       return searchFields;
   }
   /**
    * List of Field wrappers depending on Account Record type
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
   * All configured fields and fields needed to complete account queries
   */
   private static Set<String> accountFields {
       get {
           if (accountFields == null) {
               accountFields = new Set<String> {
                   'Id',
                   'HealthCloudGA__SourceSystemId__c',
                   'RecordTypeId',
                   'RecordType.Name',
                   'RecordType.DeveloperName',
                   'isPersonAccount',
                   'PJN_Veeva_Network_Id__c'
               };

               for (PJN_FieldWrapper wrapper : queryFields) {
                   if (wrapper.objectName == 'Account') {
                       accountFields.add(wrapper.fieldName);
                   }
               }
           }
           return accountFields;
       }
       set;
   }

   /**
   * All configured fields and fields needed to complete contact info queries
   */
   private static Set<String> contactInfoFields {
       get {
           if (contactInfoFields == null) {
               contactInfoFields = new Set<String>{
                   'Id',
                   'PJN_Account__c',
                   'RecordTypeId',
                   'RecordType.Name',
                   'PJN_Veeva_Network_Id__c',
                   'PJN_External_ID__c'
               };

               for (PJN_FieldWrapper wrapper : queryFields) {
                   if (wrapper.objectName == 'PJN_Contact_Information__c') {
                       contactInfoFields.add(wrapper.fieldName);
                   }
               }
           }
           return contactInfoFields;
       }
       set;
   }

   /**
   * All configured fields and fields needed to complete contact info queries
   */
   private static Set<String> carePlanFields {
       get {
           if (carePlanFields == null) {
               carePlanFields = new Set<String>{
                   'Id',
                   'AccountId'
               };

               for (PJN_FieldWrapper wrapper : queryFields) {
                   if (wrapper.objectName == 'Case') {
                       carePlanFields.add(wrapper.fieldName);
                   }
               }
           }
           return carePlanFields;
       }
       set;
   }

   /**
   * @description - all configured fields and fields needed to complete contact info queries
   */
   private static Set<String> affiliationFields {
       get {
           if (affiliationFields == null) {
               affiliationFields = new Set<String>{
                   'Id',
                   'PJN_Child_Account__c',
                   'PJN_Parent_Account__c',
                   'PJN_Veeva_Network_ID__c',
                   'MVN_External_Id__c'
               };

               for (PJN_FieldWrapper wrapper : queryFields) {
                   if (wrapper.objectName == 'PJN_Affiliation__c') {
                       affiliationFields.add(wrapper.fieldName);
                   }
               }
           }
           return affiliationFields;
       }
       set;
   }

   /**
   * Inner class used to facilitate a search
   */
   private class SearchWrapper {
       String objectName;
       String recordTypeName;
       Set<String> searchTerms;
       Map<PJN_FieldWrapper, Object> filterMap;

       private DescribeSObjectResult objDescribe;

       public SearchWrapper(String objName, List<String> recordTypeDevNames) {
            this(objName, '');
            if (recordTypeDevNames != null && !recordTypeDevNames.isEmpty()) {
                this.recordTypeName = String.join(recordTypeDevNames, ';');
            }
       }
       public SearchWrapper(String objName, String recTypeName) {
           objectName = objName;
           recordTypeName = recTypeName;
           searchTerms = new Set<String>();
           filterMap = new Map<PJN_FieldWrapper, Object>();
           objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
       }

       /**
        * Based on the field wrapper and the value add the search term to the correct place
        * @param field - PJN_FieldWrapper for the input field
        * @param value - Object representing the value provided in the request
        */
       public void addTerm(PJN_FieldWrapper field, Object value) {
           if (searchableTypes.contains(field.fieldDescribe.getType())) {
               searchTerms.add((String) value);
           } else {
               filterMap.put(field, value);
           }
       }

       public Boolean hasTerm() {
           return searchTerms.size() > 0 || filterMap.size() > 0;
       }

       /**
        * Perform the search. If any searchterms provided execute a SOSL search otherwise
        * execute a SOQL query using the filters
        * @param accountFilterMap - Filters from the account search to be applied to CI searches
        */
       public void search(Map<PJN_FieldWrapper, Object> accountFilterMap) {
           String accountIdField = objectName == 'Account' ? 'Id' : 'PJN_Account__c';

           if (searchTerms.size() > 0) {
               performSOSLSearch(accountFilterMap, accountIdField);
           } else if (filterMap.size() > 0) {
               if (filterMap.size() == 1 && filterMap.containsKey(acctStatusWrapper)) {
                   return;
               }
               performSOQLQuery(accountFilterMap, accountIdField);
           }
       }

       /**
        * Build a SOSL String and execute the search. Update the currentAccountIds
        * based on records located
        * @param accountFilterMap - Filters from the account search to be applied to CI searches
        * @param accountIdField - The field representing the account id in this search
        */
       private void performSOSLSearch(Map<PJN_FieldWrapper, Object> accountFilterMap, String accountIdField) {
           String searchType = 'ALL';
           if (objectName == 'PJN_Contact_Information__c') {
               if (recordTypeName.contains('Phone') || recordTypeName.contains('Fax')) {
                   searchType ='PHONE';
               } else if (recordTypeName.contains('Email')) {
                   searchType = 'EMAIL';
               }
           }

           String searchString = String.join(new List<String>(searchTerms), ' AND ');
           String soslString = 'FIND \'' + String.escapeSingleQuotes(searchString)
               + '\' IN ' + searchType + ' FIELDS RETURNING ' + objectName + ' (' + accountIdField;

           soslString += buildWhereClause(accountFilterMap);

           soslString += ')';
           System.debug('### soslString: ' + soslString + ' ' + recordTypeName);
           searchStrings.add(soslString);

           List<List<SObject>> results = Search.query(soslString);
           // after search is executed rebuild curentAccountIds
           currentAccountIds = new Set<Id>();
           if (!results.isEmpty()) {
               if (results[0].size() == SEARCH_MAX) { // we are at the SOSL limit, there may be more results
                   String searchErrorType = objDescribe.getLabel();
                   if (String.isNotBlank(recordTypeName)) {
                       // only get record type when doing CI search
                       searchErrorType = objDescribe.getRecordTypeInfosByDeveloperName()
                           .get(recordTypeName.split(';')[0])
                           .getName();
                   }
                   throw new PJNSearchException(
                       String.format(Label.PJN_Account_Search_Too_Many_Results, new List<String>{searchErrorType})
                   );
               }
               for (SObject result : results[0]) {
                   currentAccountIds.add((Id) result.get(accountIdField));
               }
           }
       }

       /**
        * Build a query string and execute a query. Update currentAccountIds
        * based on records located
        * @param accountFilterMap - Filters from the account search to be applied to CI searches
        * @param accountIdField - The field representing the account id in this search
        */
       private void performSOQLQuery(Map<PJN_FieldWrapper, Object> accountFilterMap, String accountIdField) {
           String soqlString = 'SELECT ' + accountIdField
               + ' FROM ' + objectName
               + buildWhereClause(accountFilterMap);

           System.debug('### soqlString: ' + soqlString);
           searchStrings.add(soqlString);

           List<SObject> results = Database.query(soqlString);
           // after query is executed rebuild curentAccountIds
           currentAccountIds = new Set<Id>();
           for (SObject result : results) {
               currentAccountIds.add((Id) result.get(accountIdField));
           }
       }

       /**
        * Build out the where clause for the SOQL query string or SOSL search string
        * @param accountFilterMap - additional filters from the account search to be applied to any ci search
        * @returns `String`
        */
       private String buildWhereClause(Map<PJN_FieldWrapper, Object> accountFilterMap) {
           List<String> whereClauses = new List<String>();
           // for each filter create a where clause entry
           if (filterMap.size() > 0) {
               for (PJN_FieldWrapper field: filterMap.keySet()) {
                   String value = String.valueOf(filterMap.get(field));
                   whereClauses.add(buildWhere(field, value));
               }
           }

           // if any account filters have been passed in, process them and prepend with
           // PJN_Account__r. so that the query fiilters on account attributes
           if (accountFilterMap != null && accountFilterMap.size() > 0) {
               for (PJN_FieldWrapper field: accountFilterMap.keySet()) {
                   String value = String.valueOf(accountFilterMap.get(field));
                   whereClauses.add('PJN_Account__r.' + buildWhere(field, value));
               }
           }

           if (currentAccountIds != null) {
               // based on the account search happening first, followed by all contact info searches
               // we can always use PJN_Account__c as current ids will ALWAYS be null for the first
               // search (the account search) so this where clause won't be added to an account
               // search/query
               whereClauses.add('PJN_Account__c IN :currentAccountIds');
           } else if (objectName == 'Account') {
               whereClauses.add('isPersonAccount = :isPersonSearch');
           }

           if (String.isNotBlank(recordTypeName)) {
               List<String> recordTypeNames = recordTypeName.split(';');
               List<String> recordTypeFilters = new List<String>();

               for (String name : recordTypeNames) {
                   recordTypeFilters.add('RecordType.DeveloperName = \'' + name + '\'');
               }

               String filter = '(' + String.join(recordTypeFilters, ' OR ') + ')';
               whereClauses.add(filter);
           }

           String whereClause = '';
           if (!whereClauses.isEmpty()) {
               whereClause = ' WHERE ' + String.join(whereClauses, ' AND ');
           }

           if (currentAccountIds == null && objectName == 'PJN_Contact_Information__c' && !accountSearchRecTypes.isEmpty()) {
                //The search has no account search terms so the account search (first search) wasn't performed
                // but is filtering on at least one account record type so get the initial set of currentAccountIds
                // so they are filtered to the correct record types
                whereClause += ' AND PJN_Account__r.RecordType.DeveloperName IN :accountSearchRecTypes';
            }

           return whereClause;
       }

       /**
        * Given a field and a value format a string for a where clause
        * @param field - PJN_FieldWrapper holding info about the field
        * @param value - the value provided in the search request for this field
        * @returns `String` - the field/value pair to filter on in the search/query
        */
       private String buildWhere(PJN_FieldWrapper field, String value) {
           Set<Schema.DisplayType> quoteableTypes = new Set<Schema.DisplayType> {
               Schema.DisplayType.Reference,
               Schema.DisplayType.Picklist,
               Schema.DisplayType.URL
           };

           // PJN Status is a PJN owned field and should NOT change
           if (field.fieldDescribe.getName().toLowerCase() == 'pjn_status__c') {
               List<String> statusFilters = new List<String>();
               for (String statusAllowed : value.split(',')) {
                   if (String.isNotBlank(statusAllowed)) {
                       statusFilters.add('\'' + statusAllowed.trim() + '\'');
                   }
               }
               return field.fieldDescribe.getName() + ' IN (' + String.join(statusFilters, ',') + ')';
           } else if (field.fieldDescribe.getType() == DisplayType.Datetime) {
               value = value.replaceAll(' ', 'T') + 'Z';
           } else if (field.fieldDescribe.getType() == DisplayType.Date) {
               value = value.substringBefore(' ');
           } else if (quoteableTypes.contains(field.fieldDescribe.getType())) {
               value = '\'' + value + '\'';
           }

           return field.fieldDescribe.getName() + '=' + value;
       }
   }
}