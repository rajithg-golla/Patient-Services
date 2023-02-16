/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Handler for the network account search
 */
public with sharing class PJN_NetworkSearchHdlr implements PJN_AccountSearchIntf {
    private static PJN_Global_Setting__mdt pjnSetting = PJN_Utilities.globalSetting;
    private static final Integer CI_QUERY_MAX_RECORDS = 20000;
    private static final String ADDRESS_REC_TYPE = 'PJN_Address';
    // map of poulated info - outer key is object, inner key is field name
    private static Map<String, Map<String, Object>> populatedInfoByObject;
    private static Boolean isPersonSearch;
    private static String  recordTypeId;
    private static String recordTypeInfoDevName;

    private static PJN_Network_Object_Setting__mdt networkAccountSetting = PJN_NetworkObjectSetting.getSettingByName('Account');
    private static PJN_Network_Object_Setting__mdt networkAddressSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_Contact_Information__c');
    private static PJN_Network_Object_Setting__mdt networkLicenseSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_License__c');
    private static PJN_Network_Object_Setting__mdt networkAffilitionSetting = PJN_NetworkObjectSetting.getSettingByName('PJN_Affiliation__c');
    static Map<PJN_Network_Field_Mapping__mdt, Map<String, PJN_Network_Value_Mapping__mdt>> inboundValueMappingsByNameByFieldMapping = new Map<PJN_Network_Field_Mapping__mdt, Map<String, PJN_Network_Value_Mapping__mdt>>();

    // Given a search request return a list of account search results
    public List<PJN_AccountSearchRslt> search(PJN_AccountSearchRqst req) {
        isPersonSearch = req.isPersonSearch;
        recordTypeId = req.account.RecordTypeId;
        recordTypeInfoDevName = String.isNotBlank(recordTypeId) ?
            Account.getSObjectType().getDescribe().getRecordTypeInfosById().get(recordTypeId).getDeveloperName() :
            null;

        Boolean currentRecordTypeAllowed = networkAccountSetting != null && String.isNotBlank(networkAccountSetting.PJN_Search_Record_Types_Allowed__c)
            && (networkAccountSetting.PJN_Search_Record_Types_Allowed__c.split(',').contains(recordTypeInfoDevName) || String.isBlank(recordTypeInfoDevName));

        if (!currentRecordTypeAllowed) {
            return new List<PJN_AccountSearchRslt>();
        }

        System.debug((isPersonSearch ? 'Person' : 'Business') + ' search for ' + recordTypeId);

        populatedInfoByObject = new Map<String, Map<String, Object>>();
        populatedInfoByObject.put(
            'Account',
            getNonNulls(req.account.getPopulatedFieldsAsMap())
        );
        populatedInfoByObject.put(
            'PJN_Contact_Information__c',
            getNonNulls(req.contactInfo.getPopulatedFieldsAsMap())
        );
        populatedInfoByObject.put(
            'Case',
            new Map<String,Object>()
        );
        System.debug(populatedInfoByObject);
        String networkSearchQuery = getNetworkSearchQuery();
        System.debug('networkSearchQuery: \n\n' + networkSearchQuery);
        List<PJN_AccountSearchRslt> finalResults = searchNetworkAccounts(networkSearchQuery);

        System.debug('finalResults size: ' + finalResults.size());

        System.debug(finalResults);
        return finalResults;
    }

    private static Map<String, Object> getNonNulls(Map<String, Object> populatedFields) {
        Map<String, Object> nonNulls = new Map<String, Object>();
        System.debug(populatedFields);
        for (String field : populatedFields.keySet()) {
            if (populatedFields.get(field) != null) {
                //TODO: Determine if this test is valid across all types
                if (String.isNotBlank(String.valueOf(populatedFields.get(field)))) {
                    nonNulls.put(field, populatedFields.get(field));
                }
            }
        }
        return nonNulls;
    }

    private static String getNetworkSearchQuery() {
        String accountType = isPersonSearch ? 'HCP' : 'HCO';

        String networkSearchQuery = 'q=*&limit=' + (Integer)pjnSetting.PJN_Account_Search_Max_Results__c + '&types=' + accountType + '&statuses=A&sortResultChildren=true&includeMasterResults=' + Boolean.valueOf(pjnSetting.PJN_Include_Open_Data_Network__c);

        String filters = '';
        String fieldQueries = '';

        for (String sobjectName : populatedInfoByObject.keySet()) {
            Map<String, Object> populatedFields = populatedInfoByObject.get(sobjectName);
            List<PJN_Network_Field_Mapping__mdt> networkFieldMappings = (sobjectName == 'Account' && String.isNotBlank(recordTypeInfoDevName)) ?
                PJN_NetworkObjectSetting.getMappingsByNameAndRecordType(sobjectName, recordTypeInfoDevName) :
                PJN_NetworkObjectSetting.getMappingsByName(sobjectName);

            String networkObjectName = '';

            if (sobjectName == 'Account') {
                networkObjectName = accountType.toLowerCase() + '.';
            } else if (sobjectName == 'PJN_Contact_Information__c') {
                networkObjectName = 'address.';
            }

            Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingsByFieldName = getNetworkFieldMappingsByFieldName(networkFieldMappings);

            for (String fieldName : populatedFields.keySet()) {
                PJN_Network_Field_Mapping__mdt networkFieldMapping = networkFieldMappingsByFieldName.containsKey(fieldName) ?
                    networkFieldMappingsByFieldName.get(fieldName) :
                    null;

                if (networkFieldMapping == null) {
                    continue;
                }

                String networkValue = String.valueOf(populatedFields.get(fieldName));
                Boolean hasWildcard = networkValue.contains('*');

                for (PJN_Network_Value_Mapping__mdt networkValueMapping : networkFieldMapping.PJN_Network_Value_Mappings__r) {
                    if (networkValueMapping.PJN_Outbound__c && networkValueMapping.PJN_Value__c.equalsIgnoreCase(networkValue.substringBeforeLast('*'))) {
                        networkValue = networkValueMapping.PJN_External_Value__c;
                        break;
                    }
                }

                if (hasWildcard) {
                    fieldQueries += networkObjectName + networkFieldMapping.PJN_External_Field_Name__c + ':' + EncodingUtil.urlEncode(networkValue, 'UTF-8') + '~';
                } else {
                    filters += networkObjectName + networkFieldMapping.PJN_External_Field_Name__c + ':' + EncodingUtil.urlEncode(networkValue, 'UTF-8') + '~';
                }
            }
        }

        List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypes = String.isBlank(recordTypeInfoDevName) ?
            PJN_NetworkObjectSetting.getNetworkRecordTypeMappingsByObject('Account') :
            new List<PJN_Network_Record_Type_Mapping__mdt>();

        if (String.isNotBlank(recordTypeInfoDevName)) {
            networkRecordTypes.add(PJN_NetworkObjectSetting.getNetworkRecordTypeMappingByObjectAndRecordTypeName('Account', recordTypeInfoDevName));
        }

        if (networkRecordTypes != null && !networkRecordTypes.isEmpty()) {
            List<String> networkRecordSubTypes = new List<String>();

            for (PJN_Network_Record_Type_Mapping__mdt networkRecordType : networkRecordTypes) {
                if (networkRecordType == null || String.isBlank(networkRecordType.PJN_Network_Record_SubType__c)) {
                    continue;
                }

                networkRecordSubTypes.add(networkRecordType.PJN_Network_Record_SubType__c);
            }

            if (networkRecordSubTypes != null && !networkRecordSubTypes.isEmpty()) {
                filters += accountType.toLowerCase() + '.' + accountType.toLowerCase() + '_type__v:' + EncodingUtil.urlEncode(String.join(networkRecordSubTypes, ','), 'UTF-8') + '~';
            }
        }

        if (filters.contains('address.')) {
            filters += 'address.address_status__v:A~';
        }

        if (String.isNotBlank(filters)) {
            networkSearchQuery += '&filters=' + filters.substringBeforeLast('~');
        }
        if (String.isNotBlank(fieldQueries)) {
            networkSearchQuery += '&fieldQueries=' + fieldQueries.substringBeforeLast('~');
        }

        return networkSearchQuery;
    }

    private static Map<String, PJN_Network_Field_Mapping__mdt> getNetworkFieldMappingsByFieldName(List<PJN_Network_Field_Mapping__mdt> networkFieldMappings) {
        Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingsByFieldName = new Map<String, PJN_Network_Field_Mapping__mdt>();

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
            networkFieldMappingsByFieldName.put(networkFieldMapping.PJN_Field_API_Name__c, networkFieldMapping);
        }

        return networkFieldMappingsByFieldName;
    }

    // Insert a record into the database
    public Id insertAccountDetails(PJN_AccountSearchRslt searchResult) {

        // make sure Account is pulled into Network from OpenData
        retrieveAccountFromOpenData(searchResult);

        PJN_DCR.updateFromNetwork = true;
        insert searchResult.accountDetail;

        Map<String, Id> contactInfoIdByNetworkId = new Map<String, Id>();
        if (searchResult.contactInfoByNetworkId != null) {
            String accountParentFieldName = String.isNotBlank(networkAddressSetting.PJN_Parent_Account_Field_Name__c) ?
                networkAddressSetting.PJN_Parent_Account_Field_Name__c :
                'PJN_Account__c';

            for (PJN_Contact_Information__c ci : searchResult.contactInfoByNetworkId.values()) {
                ci.put(accountParentFieldName, searchResult.accountDetail.Id);
            }

            insert searchResult.contactInfoByNetworkId.values();
        }

        if (searchResult.licensesByNetworkId != null) {
            String accountParentFieldName = String.isNotBlank(networkLicenseSetting.PJN_Parent_Account_Field_Name__c) ?
                networkLicenseSetting.PJN_Parent_Account_Field_Name__c :
                'PJN_Account__c';

            for (PJN_License__c license : searchResult.licensesByNetworkId.values()) {
                license.put(accountParentFieldName, searchResult.accountDetail.Id);

                if (license.PJN_Contact_Information__c != null && searchResult.contactInfoByNetworkId != null && searchResult.contactInfoByNetworkId.containsKey(license.PJN_Contact_Information__c)) {
                    license.PJN_Contact_Information__c = ((PJN_Contact_Information__c) searchResult.contactInfoByNetworkId.get(license.PJN_Contact_Information__c)).Id;
                } else if (license.PJN_Contact_Information__c != null) {
                    license.PJN_Contact_Information__c = null;
                }
            }

            insert searchResult.licensesByNetworkId.values();
        }

        if (searchResult.affiliationsByNetworkId != null) {
            String accountParentFieldName = String.isNotBlank(networkAffilitionSetting.PJN_Parent_Account_Field_Name__c) ?
                networkAffilitionSetting.PJN_Parent_Account_Field_Name__c :
                'PJN_Child_Account__c';

            Map<String, Id> parentIdByExternalId = new Map<String, Id>();

            for (PJN_Affiliation__c affiliation : searchResult.affiliationsByNetworkId.values()) {
                parentIdByExternalId.put(affiliation.PJN_Parent_Account__c, null);
            }

            List<Account> parentHCOs = [
                SELECT
                    Id,
                    PJN_Veeva_Network_Id__c
                FROM
                    Account
                WHERE
                    PJN_Veeva_Network_Id__c IN :parentIdByExternalId.keySet()
            ];

            for (Account parentHCO : parentHCOs) {
                parentIdByExternalId.put(parentHCO.PJN_Veeva_Network_Id__c, parentHCO.Id);
            }

            List<PJN_Affiliation__c> affiliations = new List<PJN_Affiliation__c>();

            for (PJN_Affiliation__c affiliation : searchResult.affiliationsByNetworkId.values()) {
                Id parentHCOId = parentIdByExternalId.get(affiliation.PJN_Parent_Account__c);

                if (parentHCOId == null) {
                    continue;
                }

                affiliation.put(accountParentFieldName, searchResult.accountDetail.Id);
                affiliation.PJN_Parent_Account__c = parentHCOId;
                affiliations.add(affiliation);
            }

            upsert affiliations PJN_Veeva_Network_Id__c;
        }

        return searchResult.accountDetail.Id;
    }

    // Given a searchRequest return results with all information needed to insert into database
    public List<PJN_AccountSearchRslt> getAccountsWithDetails(PJN_AccountSearchRqst searchRequest) {
        //TODO: implement
        return new List<PJN_AccountSearchRslt>();
    }

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

    private void retrieveAccountFromOpenData(PJN_AccountSearchRslt searchResult) {
        String vid = searchResult.accountDetail.PJN_Veeva_Network_Id__c;

        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout(
            '/entity/' + vid,
            'GET',
            'application/json'
        );

        System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::retrieve entity:' + networkCallout);

        PJN_NetworkResponse response = networkCallout.callVeevaNetwork(null);

        System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::retrieve entity respone:' + response);
    }

    private static void filterInboundValueMappings(List<PJN_Network_Field_Mapping__mdt> networkFieldMappings) {
        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
            inboundValueMappingsByNameByFieldMapping.put(
                networkFieldMapping,
                new Map<String, PJN_Network_Value_Mapping__mdt>()
            );
            if (networkFieldMapping.PJN_Network_Value_Mappings__r != null) {
                for (PJN_Network_Value_Mapping__mdt valueMapping : networkFieldMapping.PJN_Network_Value_Mappings__r) {
                    if (valueMapping.PJN_Inbound__c) {
                        inboundValueMappingsByNameByFieldMapping
                            .get(networkFieldMapping)
                            .put(valueMapping.PJN_External_Value__c, valueMapping);
                    }
                }
            }
        }
    }
    private static List<PJN_AccountSearchRslt> searchNetworkAccounts(String networkSearchQuery) {
        List<PJN_AccountSearchRslt> results = new List<PJN_AccountSearchRslt>();

        PJN_NetworkCallout networkCallout = new PJN_NetworkCallout(
            '/search?' + networkSearchQuery,
            'GET',
            'application/json'
        );

        System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::Query callout: ' + networkSearchQuery);

        PJN_PublishTransactionLog.logType = 'Search';

        PJN_NetworkResponse response = networkCallout.callVeevaNetwork(null);

        System.debug('response: ' + response);

        if (response.entities == null || response.entities.isEmpty()) {
            return results;
        }

        String accountRecordTypeName = isPersonSearch ? 'PJN_Physician' : 'PJN_Organization';

        String recordTypeDevNameForMapping = String.isNotBlank(recordTypeInfoDevName) ?
            recordTypeInfoDevName :
            accountRecordTypeName;
        Map<String, RecordType> recordTypeByDeveloperName = getRecordTypeByDeveloperName('Account');

        Map<String, PJN_Network_Field_Mapping__mdt> accNetworkFieldMappings = getNetworkFieldMappingsByNetworkFieldName(String.isNotBlank(recordTypeDevNameForMapping) ? PJN_NetworkObjectSetting.getMappingsByNameAndRecordType('Account', recordTypeDevNameForMapping) : PJN_NetworkObjectSetting.getMappingsByName('Account'));
        filterInboundValueMappings(accNetworkFieldMappings.values());
        Map<String, PJN_Network_Field_Mapping__mdt> addressNetworkFieldMappings = getNetworkFieldMappingsByNetworkFieldName(PJN_NetworkObjectSetting.getMappingsByName('PJN_Contact_Information__c'));
        filterInboundValueMappings(addressNetworkFieldMappings.values());
        Map<String, PJN_Network_Field_Mapping__mdt> licenseNetworkFieldMappings = getNetworkFieldMappingsByNetworkFieldName(PJN_NetworkObjectSetting.getMappingsByName('PJN_License__c'));
        filterInboundValueMappings(licenseNetworkFieldMappings.values());
        Map<String, PJN_Network_Field_Mapping__mdt> affiliationNetworkFieldMappings = getNetworkFieldMappingsByNetworkFieldName(PJN_NetworkObjectSetting.getMappingsByName('PJN_Affiliation__c'));
        filterInboundValueMappings(affiliationNetworkFieldMappings.values());

        for (PJN_NetworkEntity networkEntity : response.entities) {
            System.debug('networkEntity: ' + networkEntity);
            SObject currentAccount = getSObjectWithFieldsPopulated('Account', accNetworkFieldMappings, networkEntity.entity);

            String networkSubType = String.valueOf(networkEntity.entity.attributes.get(networkEntity.entityType.toLowerCase() + '_type__v'));

            PJN_Network_Record_Type_Mapping__mdt networkRecordTypeMapping = getRecordTypeMapping('Account', networkEntity.entityType, networkSubType);

            RecordType currentRecordType = networkRecordTypeMapping != null && String.isNotBlanK(networkRecordTypeMapping.PJN_Record_Type_Name__c) ?
                recordTypeByDeveloperName.get(networkRecordTypeMapping.PJN_Record_Type_Name__c) :
                recordTypeByDeveloperName.get(recordTypeDevNameForMapping);

            currentAccount.putSObject('RecordType', currentRecordType);
            currentAccount.put('RecordTypeId', currentRecordType.Id);
            currentAccount.put('PJN_Record_Type__c', currentRecordType.Name);
            PJN_AccountSearchRslt currentResult = new PJN_AccountSearchRslt (
                (Account) currentAccount,
                'PJN_NetworkSearchHdlr',
                queryFields
            );

            Boolean isAddressAllowed = networkEntity.entity.addresses != null && !networkEntity.entity.addresses.isEmpty()
                && String.isNotBlank(networkAddressSetting.PJN_SObject_Name__c) && addressNetworkFieldMappings != null && !addressNetworkFieldMappings.isEmpty();

            if (isAddressAllowed) {
                List<PJN_Contact_Information__c> addresses = new List<PJN_Contact_Information__c>();

                for (PJN_NetworkRecord networkAddress : networkEntity.entity.addresses) {
                    Boolean isAddressActive = networkAddress != null && networkAddress.attributes != null && !networkAddress.attributes.isEmpty() &&
                        networkAddress.attributes.containsKey('address_status__v') && String.valueOf(networkAddress.attributes.get('address_status__v')).toLowerCase() == 'a';

                    if (!isAddressActive) {
                        continue;
                    }

                    SObject currentAddress = getSObjectWithFieldsPopulated('PJN_Contact_Information__c', addressNetworkFieldMappings, networkAddress);
                    currentAddress.put('RecordTypeId', Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId());
                    addresses.add((PJN_Contact_Information__c) currentAddress);
                }

                currentResult.addContactInfoRecords(addresses);
            }

            Boolean isLicenseAllowed = networkEntity.entity.licenses != null && !networkEntity.entity.licenses.isEmpty()
                && String.isNotBlank(networkLicenseSetting.PJN_SObject_Name__c) && licenseNetworkFieldMappings != null && !licenseNetworkFieldMappings.isEmpty();

            if (isLicenseAllowed) {
                Map<String, PJN_License__c> licenseByNetworkId = new Map<String, PJN_License__c>();

                for (PJN_NetworkRecord networkLicense : networkEntity.entity.licenses) {
                    Boolean isLicenseActive = networkLicense != null && networkLicense.attributes != null && !networkLicense.attributes.isEmpty() &&
                        networkLicense.attributes.containsKey('license_status__v') && String.valueOf(networkLicense.attributes.get('license_status__v')).toLowerCase() == 'a';

                    if (!isLicenseActive) {
                        continue;
                    }

                    SObject currentLicense = getSObjectWithFieldsPopulated('PJN_License__c', licenseNetworkFieldMappings, networkLicense);

                    if (String.isNotBlank(networkLicense.entityType)) {
                        PJN_Network_Record_Type_Mapping__mdt networkRecordType = PJN_NetworkObjectSetting.getRecordTypeMappingByObjectAndNetworkRecordTypeName('PJN_License__c', networkLicense.entityType);

                        if (networkRecordType != null) {
                            currentLicense.put('RecordTypeId', Schema.SObjectType.PJN_License__c.getRecordTypeInfosByDeveloperName().get(networkRecordType.PJN_Record_Type_Name__c).getRecordTypeId());
                        }
                    }

                    if (String.isNotBlank(networkLicense.licenseAddressVid)) {
                        currentLicense.put('PJN_Contact_Information__c', networkLicense.licenseAddressVid);
                    }

                    licenseByNetworkId.put(networkLicense.vid, (PJN_License__c) currentLicense);
                }

                currentResult.addLicenses(licenseByNetworkId);
            }

            Boolean isAffiliationAllowed = networkEntity.entity.affiliations != null && !networkEntity.entity.affiliations.isEmpty()
                && String.isNotBlank(networkAffilitionSetting.PJN_SObject_Name__c) && affiliationNetworkFieldMappings != null && !affiliationNetworkFieldMappings.isEmpty();

            if (isAffiliationAllowed) {
                Map<String, PJN_Affiliation__c> affiliationsByNetworkId = new Map<String, PJN_Affiliation__c>();

                for (PJN_NetworkRecord networkAffiliation : networkEntity.entity.affiliations) {
                    SObject currentAffiliation = getSObjectWithFieldsPopulated('PJN_Affiliation__c', affiliationNetworkFieldMappings, networkAffiliation);

                    affiliationsByNetworkId.put(networkAffiliation.vid, (PJN_Affiliation__c) currentAffiliation);
                }

                currentResult.addAffiliations(affiliationsByNetworkId);
            }
            System.debug('currentResult: ' + currentResult);

            results.add(currentResult);
        }

        return results;
    }

    private static Map<String, RecordType> getRecordTypeByDeveloperName(String sobjectName) {
        List<RecordType> recordTypes = [
            SELECT
                Id,
                Name,
                DeveloperName
            FROM
                RecordType
            WHERE
                SobjectType = :sobjectName
        ];

        Map<String, RecordType> recordTypeByDeveloperName = new Map<String, RecordType>();

        for (RecordType rt : recordTypes) {
            recordTypeByDeveloperName.put(rt.DeveloperName, rt);
        }

        return recordTypeByDeveloperName;
    }

    private static PJN_Network_Record_Type_Mapping__mdt getRecordTypeMapping(String sobjectName, String networkRecordType, String networkSubType) {
        PJN_Network_Record_Type_Mapping__mdt resultNetworkTypeMapping;

        List<PJN_Network_Record_Type_Mapping__mdt> networkRecordTypeMappings = PJN_NetworkObjectSetting.getNetworkRecordTypeMappingsByObject(sobjectName);

        if (networkRecordTypeMappings == null) {
            return resultNetworkTypeMapping;
        }

        for (PJN_Network_Record_Type_Mapping__mdt networkRecordTypeMapping : networkRecordTypeMappings) {
            Boolean sameRecordType = networkRecordTypeMapping.PJN_Network_Record_Type__c.toLowerCase() == networkRecordType.toLowerCase()
                && ((String.IsBlank(networkRecordTypeMapping.PJN_Network_Record_SubType__c) && String.IsBlank(networkSubType))
                    || (String.IsNotBlank(networkRecordTypeMapping.PJN_Network_Record_SubType__c) && String.IsNotBlank(networkSubType) && networkRecordTypeMapping.PJN_Network_Record_SubType__c.toLowerCase() == networkSubType.toLowerCase()));
            if (sameRecordType) {
                resultNetworkTypeMapping = networkRecordTypeMapping;
                break;
            }
        }

        return resultNetworkTypeMapping;
    }

    private static SObject getSObjectWithFieldsPopulated(String sobjectName, Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappings, PJN_NetworkRecord entity) {
        SObject currentSObject = Schema.getGlobalDescribe().get(sobjectName).newSObject();

        String networkId = String.isNotBlank(entity.vid) ? entity.vid : entity.vidKey;

        if (String.isNotBlank(networkId)) {
            currentSObject.put('PJN_Veeva_Network_Id__c', networkId);
        }

        for (String fieldName : networkFieldMappings.keySet()) {
            PJN_Network_Field_Mapping__mdt networkFieldMapping = networkFieldMappings.get(fieldName);

            if (!entity.attributes.containsKey(fieldName)) {
                continue;
            }

            String fieldValue = String.valueOf(entity.attributes.get(fieldName));

            if (inboundValueMappingsByNameByFieldMapping.containsKey(networkFieldMapping)) {
                Map<String,PJN_Network_Value_Mapping__mdt> inboundValueMapByName = inboundValueMappingsByNameByFieldMapping.get(networkFieldMapping);
                if (inboundValueMapByName.containsKey(fieldValue)) {
                    fieldValue = inboundValueMapByName.get(fieldValue).PJN_Value__c;
                }
            }

            currentSObject.put(networkFieldMapping.PJN_Field_API_Name__c, getFieldValueWithFieldType(sobjectName, networkFieldMapping.PJN_Field_API_Name__c, fieldValue));
        }

        return currentSObject;
    }

    private static Map<String, Map<String,Schema.SObjectField>> fieldsByObject = new Map<String, Map<String,Schema.SObjectField>>();
    private static Object getFieldValueWithFieldType(String sobjectName, String fieldName, String fieldValue) {
        if (String.isBlank(sobjectName) || String.isBlank(fieldName) || String.isBlank(fieldValue)) {
            return fieldValue;
        }
        Object fieldValueObject = fieldValue;

        // only describe once
        if (!fieldsByObject.containsKey(sobjectName)) {
            fieldsByObject.put(sobjectName,  Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap());
        }
        Schema.DisplayType fieldType =  fieldsByObject.get(sobjectName).get(fieldName).getDescribe().getType();
        if(fieldType == Schema.DisplayType.DATE) {
            fieldValueObject = Date.valueOf(fieldValue);
        } else if(fieldType == Schema.DisplayType.DATETIME) {
            fieldValueObject = Datetime.valueOf(fieldValue);
        } else if (fieldType == Schema.DisplayType.BOOLEAN) {
            fieldValueObject = Boolean.valueOf(fieldValue);
        }

        return fieldValueObject;
    }

    private static Map<String, PJN_Network_Field_Mapping__mdt> getNetworkFieldMappingsByNetworkFieldName(List<PJN_Network_Field_Mapping__mdt> networkFieldMappings) {
        Map<String, PJN_Network_Field_Mapping__mdt> networkFieldMappingsByNetworkFieldName = new Map<String, PJN_Network_Field_Mapping__mdt>();

        for (PJN_Network_Field_Mapping__mdt networkFieldMapping : networkFieldMappings) {
            networkFieldMappingsByNetworkFieldName.put(networkFieldMapping.PJN_External_Field_Name__c, networkFieldMapping);
        }

        return networkFieldMappingsByNetworkFieldName;
    }
}