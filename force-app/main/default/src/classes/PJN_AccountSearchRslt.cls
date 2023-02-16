/**
 * @author      Mavens
 * @group       AccountSearch
 * @description Wrapper for a single search result returned from an account search
 */
public without sharing class PJN_AccountSearchRslt implements Comparable {

    @AuraEnabled public Account accountDetail;
    @AuraEnabled public String accountExternalId;
    @AuraEnabled public Map<Id, Map<String, PJN_Contact_Information__c>> contactInfoByExtIdByRecType;
    @AuraEnabled public Map<String, Object> singleResultByField;
    @AuraEnabled public String searchUtilityClass;

    public List<PJN_AccountSearchRslt> parentAccounts;
    @AuraEnabled public Map<String, PJN_License__c> licensesByNetworkId;
    @AuraEnabled public Map<String, PJN_Affiliation__c> affiliationsByNetworkId;
    public Map<String, PJN_Contact_Information__c> contactInfoByNetworkId  {
        get{
            if(contactInfoByNetworkId == null) {
                contactInfoByNetworkId = new Map<String, PJN_Contact_Information__c>();
                Map<String, PJN_Contact_Information__c> ciByNetworkId = new Map<String, PJN_Contact_Information__c>();

                for (Id recordTypeId : contactInfoByExtIdByRecType.keySet()) {
                    ciByNetworkId.putAll( contactInfoByExtIdByRecType.get(recordTypeId) );
                }
                contactInfoByNetworkId = ciByNetworkId;
            }
            return contactInfoByNetworkId;
        }
        private set;
    }

    public Map<String, PJN_Contact_Information__c> allParentContactInfoByNetworkId  {
        get{
            if(allParentContactInfoByNetworkId == null) {
                allParentContactInfoByNetworkId = new Map<String, PJN_Contact_Information__c>();
                Map<String, PJN_Contact_Information__c> ciByNetworkId = new Map<String, PJN_Contact_Information__c>();

                for(PJN_AccountSearchRslt parentASR : parentAccounts) {
                    ciByNetworkId.putAll(parentASR.contactInfoByNetworkId);
                }
                allParentContactInfoByNetworkId = ciByNetworkId;
            }
            return allParentContactInfoByNetworkId;
        }
        private set;
    }

    private List<PJN_FieldWrapper> queryFields;

    public PJN_AccountSearchRslt(Account acct,
                                List<PJN_Contact_Information__c> contactInformation,
                                String searchUtilityClass,
                                List<PJN_FieldWrapper> queryFields) {
        this.accountDetail = acct;
        this.accountExternalId = getAccountIdentifier();
        this.searchUtilityClass = searchUtilityClass;
        this.contactInfoByExtIdByRecType = new Map<Id, Map<String, PJN_Contact_Information__c>>();
        this.queryFields = queryFields;
        initializeOtherObjects();
        arrangeContactInfo(contactInformation);
        addAffiliationRecords(acct.Affiliation__r);
    }

    public PJN_AccountSearchRslt(Account acct, String searchUtilityClass, List<PJN_FieldWrapper> queryFields) {
        this.accountDetail = acct;
        this.accountExternalId = getAccountIdentifier();
        this.searchUtilityClass = searchUtilityClass;
        this.contactInfoByExtIdByRecType = new Map<Id, Map<String, PJN_Contact_Information__c>>();
        this.queryFields = queryFields;
        initializeOtherObjects();
        arrangeContactInfo(acct.PJN_Contact_Information__r);
        addAffiliationRecords(acct.Affiliation__r);
    }

    private void initializeOtherObjects() {
        this.parentAccounts = new List<PJN_AccountSearchRslt>();
        this.licensesByNetworkId = new Map<String, PJN_License__c>();
        this.affiliationsByNetworkId = new Map<String, PJN_Affiliation__c>();
    }

    private void arrangeContactInfo(List<PJN_Contact_Information__c> contactInformation) {
        for (PJN_Contact_Information__c contactInfo : contactInformation) {
            String recTypeId = getPJNRecordTypeId(contactInfo.RecordTypeId);

            if (!this.contactInfoByExtIdByRecType.containsKey(recTypeId)) {
                this.contactInfoByExtIdByRecType.put(recTypeId, new Map<String, PJN_Contact_Information__c>());
            }

            String contactInfoIdentifier = getContactInfoIdentifier(contactInfo);

            // if record doesn't already exist in the map, add it
            if (!this.contactInfoByExtIdByRecType.get(recTypeId).containsKey(contactInfoIdentifier)) {
                this.contactInfoByExtIdByRecType.get(recTypeId).put(contactInfoIdentifier, contactInfo);
            }
        }
    }

    // We can configure multiple record types to map to a "Type" (phone, email, address, fax)
    // PJN has a core record type that is used for each type. to display results we need to map
    // custom types back the core types and return that record type id
    private String getPJNRecordTypeId(Id recordTypeId) {
        Map<Id, RecordTypeInfo> ciRecTypesById = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosById();
        Map<String, RecordTypeInfo> ciRecTypesByDevName = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();

        PJN_Global_Setting__mdt globalSetting = PJN_Utilities.globalSetting;

        RecordTypeInfo rtInfo = ciRecTypesById.get(recordTypeId);
        String rtDevName = rtInfo.DeveloperName;

        Set<String> addressRecordTypes = new Set<String>(globalSetting.PJN_Contact_Info_Address_Record_Types__c.deleteWhitespace().split(';'));
        if (addressRecordTypes.contains(rtDevName)) {
            return ciRecTypesByDevName.get('PJN_Address').getRecordTypeId();
        }

        Set<String> phoneRecordTypes = new Set<String>(globalSetting.PJN_Contact_Info_Phone_Record_Types__c.deleteWhitespace().split(';'));
        if (phoneRecordTypes.contains(rtDevName)) {
            return ciRecTypesByDevName.get('PJN_Phone').getRecordTypeId();
        }

        Set<String> emailRecordTypes = new Set<String>(globalSetting.PJN_Contact_Info_Email_Record_Types__c.deleteWhitespace().split(';'));
        if (emailRecordTypes.contains(rtDevName)) {
            return ciRecTypesByDevName.get('PJN_Email').getRecordTypeId();
        }

        Set<String> faxRecordTypes = new Set<String>(globalSetting.PJN_Contact_Info_Fax_Record_Types__c.deleteWhitespace().split(';'));
        if (faxRecordTypes.contains(rtDevName)) {
            return ciRecTypesByDevName.get('PJN_Fax').getRecordTypeId();
        }

        return null;
    }

    public String getAccountIdentifier() {
        //TODO get external id when present
        if (accountDetail.PJN_Veeva_Network_Id__c != null) {
            return accountDetail.PJN_Veeva_Network_Id__c;
        }
        if (accountDetail.HealthCloudGA__SourceSystemId__c != null) {
            return accountDetail.HealthCloudGA__SourceSystemId__c;
        }
        return accountDetail.Id;
    }

    public String getContactInfoIdentifier(PJN_Contact_Information__c contactInfo) {

        // if (String.isBlank(contactInfo.PJN_Veeva_Network_Id__c) && String.isBlank(contactInfo.Id)) {
        //     throw new MED_SearchException('Search Result Contact Info Records must have either an Id or an External Id.');
        // }

        if (String.isNotBlank(contactInfo.PJN_Veeva_Network_Id__c)) {
            return contactInfo.PJN_Veeva_Network_Id__c;
        }
        if (contactInfo.PJN_External_Id__c != null) {
            return contactInfo.PJN_External_Id__c;
        }

        return contactInfo.Id;
    }

    public List<PJN_Contact_Information__c> getContactInfoRecords() {
        System.debug('contactInfoByNetworkId: '+contactInfoByNetworkId.keySet());
        return contactInfoByNetworkId.values();
    }

    public List<PJN_Contact_Information__c> getContactInfoForRecordType(Id recTypeId) {
        if (!contactInfoByExtIdByRecType.containsKey(recTypeId)) {
            return new List<PJN_Contact_Information__c>();
        }

        return contactInfoByExtIdByRecType.get(recTypeId).values();
    }

    public void addContactInfoRecords(List<PJN_Contact_Information__c> contactInformation) {
        arrangeContactInfo(contactInformation);
    }

    private static Map<String, Map<String,Schema.SObjectField>> fieldsByObject = new Map<String, Map<String,Schema.SObjectField>>();
    @TestVisible
    private String getDisplayValue(Object value, DisplayType fieldDt, String fieldName, String objectName) {
        String valueString;

        if (value == null) {
            valueString = '';
        } else if (fieldDt == DisplayType.Date) {
            valueString = ((Date) value).format();
        } else if (fieldDt == DisplayType.DateTime) {
            valueString = ((DateTime) value).format();
        } else if (fieldDt == DisplayType.Boolean) {
            if ((Boolean) value) {
                if (!fieldsByObject.containsKey(objectName)) {
                    fieldsByObject.put(objectName,  Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
                }
                valueString = fieldsByObject.get(objectName).get(fieldName).getDescribe().getLabel();
            }
        }  else {
            valueString = String.valueOf(value);
        }

        return valueString;
    }

    private static Map<String,Schema.SObjectField> accountFields = SObjectType.Account.fields.getMap();
    private static Map<String, RecordTypeInfo> contactInfoRecordTypes = PJN_Contact_Information__c.sObjectType
        .getDescribe()
        .getRecordTypeInfosByDeveloperName();

    public void setSingleResultByField(List<PJN_FieldWrapper> queryFields) {
        singleResultByField = new Map<String, String>{
            'acctId' => accountDetail.Id,
            'acctExtId' => accountExternalId
        };

        for (PJN_FieldWrapper wrapper : queryFields) {
            if (wrapper.setting.PJN_Object__c == 'Account') {
                //System.debug('accountDetail ' + accountDetail + ' ' + accountDetail.get(wrapper.setting.PJN_Field__c));
                Object value = accountDetail.get(wrapper.setting.PJN_Field__c);
                DisplayType fieldDt = accountFields
                    .get(wrapper.setting.PJN_Field__c)
                    .getDescribe()
                    .getType();

                singleResultByField.put(
                    wrapper.objectFieldName,
                    getDisplayValue(value, fieldDt, wrapper.setting.PJN_Field__c, 'Account')
                );
                continue;
            }

            String concatenatedString = '';
            Boolean isFirst = true;
            if (wrapper.isContactInfoField) {
                Id recTypeId;
                try {
                    recTypeId = contactInfoRecordTypes
                            .get(wrapper.setting.PJN_Contact_Info_Record_Type__c)
                            .getRecordTypeId();
                } catch (Exception ex) {
                    throw new AuraHandledException(
                        'Error retrieving Contact Info Record Type for Field Setting: ' +
                        wrapper.setting.MasterLabel
                    );
                }

                if (contactInfoByExtIdByRecType.containsKey(recTypeId)) {
                    List<PJN_Contact_Information__c> contactInfos =
                        contactInfoByExtIdByRecType.get(recTypeId).values();

                    for (PJN_Contact_Information__c contactInfo : contactInfos) {
                        if (!isFirst) {
                            concatenatedString += '\n';
                        }
                        isFirst = false;
                        DisplayType fieldDt = SObjectType.PJN_Contact_Information__c.fields
                            .getMap()
                            .get(wrapper.setting.PJN_Field__c)
                            .getDescribe()
                            .getType();
                        concatenatedString += getDisplayValue(
                            contactInfo.get(wrapper.setting.PJN_Field__c),
                            fieldDt,
                            wrapper.setting.PJN_Field__c,
                            'PJN_Contact_Information__c'
                        );
                    }
                }
            }

            if (wrapper.isCaseField) {
                for (Case currentCase : accountDetail.Cases) {
                    if (!isFirst) {
                        concatenatedString += '\n';
                    }
                    isFirst = false;
                    DisplayType fieldDt = SObjectType.Case.fields
                        .getMap()
                        .get(wrapper.setting.PJN_Field__c)
                        .getDescribe()
                        .getType();
                    concatenatedString += getDisplayValue(
                        currentCase.get(wrapper.setting.PJN_Field__c),
                        fieldDt,
                        wrapper.setting.PJN_Field__c,
                        'Case'
                    );
                }
            }
            singleResultByField.put(wrapper.objectFieldName, concatenatedString);
        }

        singleResultByField.put('AccountRecordTypeId', accountDetail.RecordTypeId);
        singleResultByField.put('AccountRecordType.Name', accountDetail.RecordType.Name);
        singleResultByField.put('AccountRecordType.DeveloperName', accountDetail.RecordType.DeveloperName);

        //System.debug('singleResultByField' + singleResultByField);
    }

    public void addParentAccounts(List<PJN_AccountSearchRslt> parentResults) {
        parentAccounts.addAll(parentResults);
    }

    public List<PJN_AccountSearchRslt> getParentAccounts() {
        return parentAccounts;
    }

    public List<PJN_Contact_Information__c> getAllParentContactInfo() {
        System.debug('allParentContactInfoByNetworkId: '+allParentContactInfoByNetworkId.keySet());
        return allParentContactInfoByNetworkId.values();
    }

    public void addLicenses(Map<String, PJN_License__c> licensesByNetworkIdResults) {
        licensesByNetworkId.putAll(licensesByNetworkIdResults);
    }

    public Map<String, PJN_License__c> getLicensesByNetworkId() {
        return licensesByNetworkId;
    }

    public void addAffiliationRecords(List<PJN_Affiliation__c> affiliations) {
        if (affiliations == null) {
            return;
        }
        for (PJN_Affiliation__c affiliation : affiliations) {
            affiliationsByNetworkId.put(affiliation.Id, affiliation);
        }
    }

    public void addAffiliations(Map<String, PJN_Affiliation__c> affiliationsByNetworkIdResults) {
        affiliationsByNetworkId.putAll(affiliationsByNetworkIdResults);
    }

    public Map<String, PJN_Affiliation__c> getAffiliationsByNetworkId() {
        return affiliationsByNetworkId;
    }

    public Integer compareTo(Object compareTo) {
        PJN_AccountSearchRslt compareToRslt = (PJN_AccountSearchRslt) compareTo;
        Boolean hasLastName = false;
        try {
            hasLastName = this.accountDetail.LastName != null;
        } catch(Exception ex) {
            //must be business account
        }
        if (hasLastName) {
            //this is a person account. Don't want to rely on isPersonAccount as results may come from extrnal sources
            String thisLastName = this.accountDetail.LastName.toLowerCase();
            String compareLastName = compareToRslt.accountDetail.LastName.toLowerCase();

            if (thisLastName.compareTo(compareLastName) == 0) {
                String thisFirstName = this.accountDetail.FirstName;
                if (String.isNotBlank(thisFirstName)) {
                    thisFirstName = thisFirstName.toLowerCase();
                } else {
                    thisFirstName = '';
                }
                String compareFirstName = compareToRslt.accountDetail.FirstName;
                if (String.isNotBlank(compareFirstName)) {
                    compareFirstName = compareFirstName.toLowerCase();
                } else {
                    compareFirstName = '';
                }

                return thisFirstName.compareTo(compareFirstName);
            }
            return this.accountDetail.LastName.compareTo(compareToRslt.accountDetail.LastName);
        } else {
            String thisName = this.accountDetail.Name.toLowerCase();
            String compareName = compareToRslt.accountDetail.Name.toLowerCase();

            return thisName.compareTo(compareName);
        }
    }

}