public with sharing class PJN_AccountSearchLightningUtil {

    public static String searchContext;
    @TestVisible
    private static Map<String, List<PJN_FieldWrapper>> fieldSettingsByType;

    @AuraEnabled
    public static List<PJN_FieldWrapper> getFields(String fieldSetName, String recordTypeId) {
        System.debug('RT: ' + recordTypeId + ', FieldSetName: ' + fieldSetName);
        Boolean isPersonAccount = fieldSetName.substringBefore('_').equalsIgnoreCase('Person');
        String  recordType      = getAccountRecordTypeDevName(recordTypeId);
        searchContext = fieldSetName;

        if (fieldSettingsByType == null) {
            fieldSettingsByType = new Map<String, List<PJN_FieldWrapper>>();
        }

        if (fieldSettingsByType.containsKey(fieldSetName)) {
            return fieldSettingsByType.get(fieldSetName);
        }

        List<PJN_FieldWrapper> fields = new List<PJN_FieldWrapper>();
        List<PJN_Field_Setting__mdt> fieldSettings;

        switch on fieldSetName.substringAfterLast('_') {
            when 'Form' {
                fieldSettings = PJN_FieldSettings.accountSearchFields(
                    recordType,
                    'PJN_Search_Field_Order__c',
                    isPersonAccount
                );
            }
            when 'Results' {
                fieldSettings = new List<PJN_Field_Setting__mdt>();
                for (PJN_Field_Setting__mdt fs : PJN_FieldSettings.accountSearchFields(
                                                    recordType,
                                                    'PJN_Search_Results_Order__c',
                                                    isPersonAccount)
                ) {
                    if (fs.PJN_Show_in_Primary_Results__c) {
                        fieldSettings.add(fs);
                    }
                }
            }
            when 'Query' {
                fieldSettings = PJN_FieldSettings.accountSearchFields(
                    recordType,
                    null,
                    isPersonAccount
                );
            }
        }

        for (PJN_Field_Setting__mdt fieldSetting : fieldSettings) {
            fields.add(new PJN_FieldWrapper(fieldSetting));
        }

        fieldSettingsByType.put(fieldSetName, fields);

        return fields;
    }

    @AuraEnabled
    public static Boolean hasBusinessAccountsConfiguredForCaseSearch() {
        Boolean hasBusinessAccountRecTypesConfigured = false;
        for(PJN_Account_Type_Setting__mdt acctTypeSetting : PJN_AccountTypeSettings.allSettings) {
            if (acctTypeSetting.PJN_Include_in_Search__c
                && !acctTypeSetting.PJN_Is_Person_Record_Type__c
                && acctTypeSetting.PJN_Account_Record_Type__c != 'all_'
                && String.isNotBlank(acctTypeSetting.PJN_Acc_Lookup_Field_API_Name_For_Case__c))
            {
                hasBusinessAccountRecTypesConfigured = true;
                break;
            }
        }

        return hasBusinessAccountRecTypesConfigured;
    }

    @AuraEnabled
    public static Case getCase(Id caseId) {
        if (caseId == null) {
            return null;
        }
        return [
            SELECT
                Id,
                AccountId,
                Account.Name,
                PJN_Caregiver__c,
                PJN_Caregiver__r.Name,
                PJN_Physician__c,
                PJN_Physician__r.Name,
                PJN_Staff__c,
                PJN_Staff__r.Name,
                MVN_Consumer__c,
                MVN_Consumer__r.Name,
                MVN_Treatment_Site__c,
                MVN_Treatment_Site__r.Name,
                MVN_Organization__c,
                MVN_Organization__r.Name,
                ParentId,
                RecordType.DeveloperName,
                PJN_Enrollment_Address__c
            FROM
                Case
            WHERE
                Id = :caseId
        ];
    }

    @TestVisible
    private static Map<String, RecordTypeInfo> accountRecordTypesByDevName {
        get {
            if (accountRecordTypesByDevName == null) {
                accountRecordTypesByDevName = Schema.Account.sObjectType
                    .getDescribe()
                    .getRecordTypeInfosByDeveloperName();
            }
            return accountRecordTypesByDevName;
        }
        set;
    }

    public static String getAccountRecordTypeDevName(String rtId) {
        String devName;

        if(String.isNotBlank(rtId)) {
            System.debug('RT ID: ' + rtId);
            Schema.DescribeSObjectResult accountData = Schema.SObjectType.Account;

            Map<Id, Schema.RecordTypeInfo> rtInfoMap = accountData.getRecordTypeInfosById();
            Schema.RecordTypeInfo rtInfo = rtInfoMap.get(rtId);

            if(rtInfo != null) {
                devName = rtInfo.getDeveloperName();
            }
        }

        return devName;
    }

    @AuraEnabled
    public static List<RecordTypeWrapper> getAccountSearchRecordTypes(Boolean isPersonSearch) {
        return wrapRecordTypes(PJN_AccountTypeSettings.searchTypes(isPersonSearch));
    }

    @AuraEnabled
    public static List<RecordTypeWrapper> getAccountCreateRecordTypes(Boolean isPersonSearch){
        return wrapRecordTypes(PJN_AccountTypeSettings.createTypes(isPersonSearch));
    }

    @TestVisible
    private static List<RecordTypeWrapper> wrapRecordTypes(List<PJN_Account_Type_Setting__mdt> acctTypeSettings) {
        List<RecordTypeWrapper> wrappers = new List<RecordTypeWrapper>();
        for (PJN_Account_Type_Setting__mdt ats : acctTypeSettings) {
            if (ats.PJN_Account_Record_Type__c.toLowerCase().left(3) == 'all') {
                wrappers.add(
                    new RecordTypeWrapper('', ats.Label)
                );
            } else {
                if (accountRecordTypesByDevName.containsKey(ats.PJN_Account_Record_Type__c)) {
                    wrappers.add(
                        new RecordTypeWrapper(
                            accountRecordTypesByDevName.get(ats.PJN_Account_Record_Type__c)
                        )
                    );
                }
            }
        }

        return wrappers;
    }

    @AuraEnabled
    public static List<RecordTypeWrapper> getContactInfoRecordTypes(){
        Schema.DescribeFieldResult fieldResult = PJN_New_Contact_Info_Fields_Setting__mdt.PJN_Record_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Map<String, RecordTypeInfo> contactInfoRecordTypes = PJN_Contact_Information__c.sObjectType
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();

        List<RecordTypeWrapper> wrappers = new List<RecordTypeWrapper>();
        for( Schema.PicklistEntry pickListVal : ple){
            if (contactInfoRecordTypes.containsKey(pickListVal.getValue())) {
                wrappers.add( new RecordTypeWrapper(contactInfoRecordTypes.get(pickListVal.getValue())));
            }
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<PJN_AccountSearchRslt> search(String searchRequest){
        try {
            System.debug('Request: ' + searchRequest);
            PJN_Global_Setting__mdt globalSetting = PJN_Utilities.globalSetting;

            List<String> searchClassNames = globalSetting.PJN_Account_Search_Handler_Classes__c.split(',');
            Integer searchLimit = Integer.valueOf(globalSetting.PJN_Account_Search_Max_Results__c);

            Map<String, PJN_AccountSearchRslt> resultsMap = new Map<String, PJN_AccountSearchRslt>();
            PJN_AccountSearchRqst req = (PJN_AccountSearchRqst) JSON.deserialize(searchRequest, PJN_AccountSearchRqst.class);
            req.maxResults = searchLimit;

            for (String searchClassName : searchClassNames) {

                Type myType = Type.forName(searchClassName);

                if (myType == null) {
                    throw new AuraHandledException('Unable to instantiate instance of search for class ' + searchClassName);
                }

                PJN_AccountSearchIntf searchClass = (PJN_AccountSearchIntf) myType.newInstance();
                List<PJN_AccountSearchRslt> results = searchClass.search(req);
                // TODO : try catch the search and throw aura exception
                for (PJN_AccountSearchRslt result : results) {
                    String accountIdentifier = result.getAccountIdentifier();

                    if (!resultsMap.containsKey(accountIdentifier)) {
                        resultsMap.put(accountIdentifier, result);
                    }
                }

                req.maxResults = req.maxResults - results.size();
            }

            System.debug('Populating FieldWrapper');
            List<PJN_FieldWrapper> queryFields =
                getFields(
                    req.isPersonSearch ? 'Person_Search_Query' : 'Business_Search_Query',
                    req.account.RecordTypeId
                );

            for (PJN_AccountSearchRslt result : resultsMap.values()) {
                result.setSingleResultByField(queryFields);
            }

            List<PJN_AccountSearchRslt> finalResults = resultsMap.values();
            finalResults.sort();
            return finalResults;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Case selectAccount(Case currentCase, String originalResult){
        System.debug(originalResult);

        PJN_AccountSearchRslt searchResult = (PJN_AccountSearchRslt) JSON.deserialize(originalResult, PJN_AccountSearchRslt.class);

        String searchClassName = searchResult.searchUtilityClass;
        Type myType = Type.forName(searchClassName);

        if (myType == null) {
            throw new AuraHandledException('Unable to instantiate instance of search for class ' + searchClassName);
        }

        PJN_AccountSearchIntf searchClass = (PJN_AccountSearchIntf) myType.newInstance();
        Id accountId = searchClass.insertAccountDetails(searchResult);

        if (currentCase == null) {
            // this is a download action, not a case selection action so return a case and set the account
            // id to the new accountid, knowing that the download action won't try to set the case at all.
            return new Case(AccountId = accountId);
        }

        Account acct;
        try {
            acct = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accountId];
        } catch(System.QueryException ex) {
            throw new AuraHandledException('Error locating account with id ' + accountId);
        }

        PJN_Case_Field_Configuration__mdt caseFieldConfig;
        try {
            caseFieldConfig = [
                SELECT
                    PJN_Case_Field_API_Name__c
                FROM
                    PJN_Case_Field_Configuration__mdt
                WHERE
                    MVN_Account_Record_Type__c = :acct.RecordType.DeveloperName
                LIMIT 1
            ];
        } catch (Exception ex) {
            throw new AuraHandledException('No case field configurations for account record type');
        }

        try {
            currentCase.put(caseFieldConfig.PJN_Case_Field_API_Name__c, accountId);
        } catch (Exception ex) {
            throw new AuraHandledException('Error setting case field ' + caseFieldConfig.PJN_Case_Field_API_Name__c);
        }

        return updateCase(currentCase);
    }

    @AuraEnabled
    public static Case updateCase(Case currentCase) {
        try {
            update currentCase;
            return getCase(currentCase.Id);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class RecordTypeWrapper {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String developerName;

        public RecordTypeWrapper(String id, String label) {
            this.value = id;
            this.label = label;
            this.developerName = '';
        }

        public RecordTypeWrapper(RecordTypeInfo recTypeInfo) {
            this.value = recTypeInfo.getRecordTypeId();
            this.label = recTypeInfo.getName();
            this.developerName = recTypeInfo.getDeveloperName();
        }
    }

    @AuraEnabled
    public static Map<Id, List<PJN_New_Account_Fields_Setting__mdt>> getAccountCreationFields() {
        return PJN_NewAccountFieldSetting.settingsByRecordTypeId;
    }

    @AuraEnabled
    public static Map<String, List<PJN_New_Contact_Info_Fields_Setting__mdt>> getContactInfoCreationFields() {
        return PJN_NewContactInfoFieldSetting.settingsByRecordType;
    }

    @AuraEnabled
    public static Case createAccount(String account,
                                    String contactInfoString,
                                    Id caseId){

        Savepoint sp = Database.setSavepoint();
        try {
            // **********************
            // *** Insert Account ***
            // **********************
            Account newAccount = (Account)JSON.deserialize(account, Account.class);
            Database.SaveResult res = Database.insert(newAccount);
            processResponse(new List<Database.SaveResult>{res}, sp);

            // ************************************
            // *** Insert Contact Info Records ***
            // ************************************
            List<PJN_Contact_Information__c> contactInfo = (List<PJN_Contact_Information__c>) JSON.deserialize(
                contactInfoString,
                List<PJN_Contact_Information__c>.class
            );
            for (PJN_Contact_Information__c ci : contactInfo) {
                ci.PJN_Account__c = newAccount.Id;
            }
            List<Database.SaveResult> resList = Database.insert(contactInfo);
            processResponse(resList, sp);

            if (String.isBlank(caseId)) {
                return new Case(AccountId = newAccount.Id);
            }

            // *******************
            // *** Update case ***
            // *******************

            Map<String, PJN_Account_Type_Setting__mdt> accTypeSettingMap = PJN_AccountTypeSettings.settingsByRecordType;

            if (String.isNotBlank(caseId)) {

                Map<ID, Schema.RecordTypeInfo> acctRecTypesById = Schema.Account.sObjectType
                    .getDescribe()
                    .getRecordTypeInfosById();

                String acctRecTypeDevName = acctRecTypesById.get(newAccount.RecordTypeId).getDeveloperName();

                if (accTypeSettingMap.containsKey(acctRecTypeDevName)) {
                    Case caseToUpdate = new Case (Id = caseId);
                    caseToUpdate.put(
                        accTypeSettingMap.get(acctRecTypeDevName).PJN_Acc_Lookup_Field_API_Name_For_Case__c,
                        newAccount.Id
                    );

                    update caseToUpdate;
                }
            }
        } catch (Exception exc) {
            Database.rollback(sp);
            throw new AuraHandledException(exc.getMessage());
        }
        return getCase(caseId);
    }

    private static void processResponse(List<Database.SaveResult> resList, Savepoint sp) {
        for (Database.SaveResult res: resList) {
            if (!res.isSuccess()) {
                String errMsg = '';
                for(Database.Error err : res.getErrors()) {
                    errMsg += err.getMessage() + ';';
                }
                Database.rollback(sp);
                throw new AuraHandledException(errMsg);
            }
        }
    }

    @AuraEnabled
    public static List<PJN_Contact_Information__c> getAddresses(String accountId) {
        return [
            SELECT Id, PJN_Value__c
            FROM PJN_Contact_Information__c
            WHERE RecordType.DeveloperName = 'PJN_Address'
              AND PJN_Account__c = :accountId
        ];
    }

    @AuraEnabled
    public static string getContactInfoRecordTypeId(string developerName) {
        return Schema.SObjectType.PJN_Contact_Information__c
            .getRecordTypeInfosByDeveloperName()
            .get(developerName)
            .getRecordTypeId();
    }

    @AuraEnabled
    public static boolean setPhysicianAddress(String caseId, String addressId) {
        boolean successful = true;

        Case mainCase = new Case(
            Id = caseId,
            PJN_Enrollment_Address__c = addressId
        );

        try {
            update mainCase;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unable to set physician primary address on case: ' + e.getMessage());
            successful = false;
        }

        return successful;
    }

    @AuraEnabled
    public static boolean setNewPhysicianAddress(String caseId, PJN_Contact_Information__c address) {
        boolean successful;

        try {
            insert address;
            successful = setPhysicianAddress(caseId, address.Id);
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unable to create new physician primary address: ' + e.getMessage());
        }

        return successful;
    }

    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> pickListValuesList = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe();
        List<Schema.PicklistEntry> ple = fieldDescribe.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(new Map<String, String>{'value' => pickListVal.getValue(), 'label' => pickListVal.getLabel()});
        }
        return pickListValuesList;
    }

    @AuraEnabled
    public static String getUserCountry() {
        return [SELECT Country FROM User WHERE Id = :UserInfo.getUserId()].Country;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getFieldUpdateability(String objectName) {
        Map<String, Schema.SObjectField> des = Schema.describeSObjects(new List<String>{objectName})[0].fields.getMap();
        Map<String, Boolean> fieldUpdateability = new Map<String, Boolean>();
        for (Schema.SObjectField field : des.values()) {
            fieldUpdateability.put(field.getDescribe().getName(), field.getDescribe().isUpdateable());
        }
        return fieldUpdateability;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getConfiguredCaseFieldMapByAccountRecType(){
        Map<String, String> fieldMap = new Map<String,String>();
        for (PJN_Case_Field_Configuration__mdt config : PJN_CaseFieldConfigurations.all) {
            fieldMap.put(config.MVN_Account_Record_Type__c, config.PJN_Case_Field_API_Name__c);
        }
        return fieldMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCreatableRecordTypes(){
        List<String> creatableRecTypeIds = new List<String>();
        for(PJN_Account_Type_Setting__mdt acctTypeSetting : PJN_AccountTypeSettings.allSettings) {
            if (acctTypeSetting.PJN_Include_in_Create__c) {
                creatableRecTypeIds.add(
                    SObjectType.account
                        .getRecordTypeInfosByDeveloperName()
                        .get(acctTypeSetting.PJN_Account_Record_Type__c)
                        .getRecordTypeId()
                );
            }
        }
        return creatableRecTypeIds;
    }
}