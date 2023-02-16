/**
 * @author      Mavens
 * @date        2019-02-26
 * @description Tests for scheduled class PJN_AccountSearchLightningUtil
 */
@isTest(isParallel=true) private class PJN_AccountSearchLightningUtilTest {
    @testSetup private static void setup() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient Test'
            }
        );
        Account physician = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                'LastName' => 'Physician Test'
            }
        );

        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Main Care Plan'
            }
        );
        Case activity = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Activity Case',
                'AccountId' => patient.Id
            }
        );

        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0]) {
            List<PJN_Case_Field_Configuration__mdt> configList =
                new PJN_TestFactoryCaseFieldConfiguration().createCaseFieldsConfigurationDefaulted();

            List<CaseTeamRole> caseTeamRoleList = new List<CaseTeamRole>();
            for (PJN_Case_Field_Configuration__mdt config : configList) {
                caseTeamRoleList.add(
                    new CaseTeamRole(
                        Name = config.PJN_Case_Team_Role_Mapping__c,
                        AccessLevel = 'Read'
                    )
                );
            }

            Database.insert(caseTeamRoleList, false);
        }
    }

    @isTest static void testGetFields() {
        String patientRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Patient')
            .getRecordTypeId();

        List<PJN_FieldWrapper> formFields;
        List<PJN_FieldWrapper> formFields2;
        List<PJN_FieldWrapper> resultFields;
        List<PJN_FieldWrapper> queryFields;

        Test.startTest();
        formFields   = PJN_AccountSearchLightningUtil.getFields('Person_Form', patientRt);
        resultFields = PJN_AccountSearchLightningUtil.getFields('Person_Results', patientRt);
        queryFields  = PJN_AccountSearchLightningUtil.getFields('Person_Query', patientRt);
        // Mainly for coverage - requesting a fieldset that has previously been obtained
        formFields2  = PJN_AccountSearchLightningUtil.getFields('Person_Form', patientRt);
        Test.stopTest();

        System.assert(formFields.size()   > 0, 'Should have returned form fields');
        System.assert(resultFields.size() > 0, 'Should have returned results fields');
        System.assert(queryFields.size()  > 0, 'Should have returned query fields');
        System.assert(formFields2.size()  > 0, 'Should have returned form fields');
    }

    @isTest static void testGetCase() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Case fullCase;

        Test.startTest();
        fullCase = PJN_AccountSearchLightningUtil.getCase(activity.Id);
        Test.stopTest();

        System.assertNotEquals(null, fullCase, 'Should return a case');
        System.assertEquals(activity.Id, fullCase.Id, 'Should return same case');
        System.assertEquals('Patient Test', fullCase.Account.Name,
            'Should return additional information on the case');
    }

    @isTest static void testHasBusinessAccountsConfiguredForCaseSearch() {
        Test.startTest();
        Boolean hasBusActConfigured = PJN_AccountSearchLightningUtil.hasBusinessAccountsConfiguredForCaseSearch();
        Test.stopTest();

        Integer acctTypeSettingsForBusinessCount = [
            SELECT COUNT()
            FROM PJN_Account_Type_Setting__mdt
            WHERE PJN_Is_Person_Record_Type__c = false
            AND PJN_Account_Record_Type__c != 'all_'
            AND PJN_Include_in_Search__c = true
            AND PJN_Acc_Lookup_Field_API_Name_For_Case__c != null
        ];

        Boolean shouldHaveBusAcctConfigured = acctTypeSettingsForBusinessCount > 0;
        System.assertEquals(shouldHaveBusAcctConfigured, hasBusActConfigured);
    }

    @isTest static void testAccountRecordTypesByDevName() {
        Map<String, RecordTypeInfo> rtMap;

        Test.startTest();
        rtMap = PJN_AccountSearchLightningUtil.accountRecordTypesByDevName;
        Test.stopTest();

        System.assert(rtMap.size() > 0, 'Should return record type entries');
        System.assert(rtMap.containsKey('PJN_Patient'),
            'Should contain account record type developer names');
    }

    @isTest static void testGetAccountRecordTypeDevName() {
        String patientRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Patient')
            .getRecordTypeId();

        Test.startTest();
        System.assertEquals(null, PJN_AccountSearchLightningUtil.getAccountRecordTypeDevName(null),
            'Null record type Id should return null');
        System.assertEquals(null, PJN_AccountSearchLightningUtil.getAccountRecordTypeDevName(''),
            'Empty record type Id should return null');
        System.assertEquals(
            'PJN_Patient',
            PJN_AccountSearchLightningUtil.getAccountRecordTypeDevName(patientRT),
            'Should return developer name for valid record type Id');
        Test.stopTest();
    }

    @isTest static void testGetAccountSearchRecordTypes() {
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> personTypes;
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> businessTypes;

        Test.startTest();
        personTypes = PJN_AccountSearchLightningUtil.getAccountSearchRecordTypes(true);
        businessTypes = PJN_AccountSearchLightningUtil.getAccountSearchRecordTypes(false);
        Test.stopTest();

        System.assert(personTypes.size() > 0, 'Should have returned person record types');
        System.assert(businessTypes.size() > 0, 'Should have returned business record types');
    }

    @isTest static void testGetAccountCreateRecordTypes() {
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> personTypes;
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> businessTypes;

        Test.startTest();
        personTypes = PJN_AccountSearchLightningUtil.getAccountCreateRecordTypes(true);
        businessTypes = PJN_AccountSearchLightningUtil.getAccountCreateRecordTypes(false);
        Test.stopTest();

        System.assert(personTypes.size() > 0, 'Should have returned person record types');
        System.assert(businessTypes.size() > 0, 'Should have returned business record types');
    }

    @isTest static void testWrapRecordTypes() {
        List<PJN_Account_Type_Setting__mdt> settings = PJN_AccountTypeSettings.settingsByRecordType.values();
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> types;
        PJN_AccountSearchLightningUtil.RecordTypeWrapper wrapper;

        Test.startTest();
        types = PJN_AccountSearchLightningUtil.wrapRecordTypes(settings);
        wrapper = new PJN_AccountSearchLightningUtil.RecordTypeWrapper('Hello', 'World');
        Test.stopTest();

        System.assert(types.size() > 0, 'Should have returned record types');
        System.assertEquals('Hello', wrapper.value, 'Wrapper value not set correctly');
        System.assertEquals('World', wrapper.label, 'Wrapper label not set correctly');
        System.assertEquals('', wrapper.developerName, 'Wrapper developer name not set correctly');
    }

    @isTest static void testGetContactInfoRecordTypes() {
        List<PJN_AccountSearchLightningUtil.RecordTypeWrapper> types;

        Test.startTest();
        types = PJN_AccountSearchLightningUtil.getContactInfoRecordTypes();
        Test.stopTest();

        System.assert(types.size() > 0, 'Should have returned record types');
    }

    @isTest static void testSearch() {
        PJN_TestFactoryGlobalSetting.setMock();
        List<Id> fixedSearchResults = new List<Id>();
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        fixedSearchResults.add(patient.Id);

        String request = '{"account":{"RecordTypeId":"' + patient.RecordTypeId + '","LastName":"P*"},"contactInfo":{},"isPersonSearch":true}';

        List<PJN_AccountSearchRslt> results;
        Test.startTest();
        Test.setFixedSearchResults(fixedSearchResults);
        results = PJN_AccountSearchLightningUtil.search(request);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return the list of results');
        System.assertEquals(1, results.size(), 'Incorrect number of results returned');
    }

    @isTest static void testSelectAccount() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlan = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        String original = '{"accountDetail":{"Id":"' + patient.Id + '","RecordTypeId":"' + patient.RecordTypeId + '","IsPersonAccount":true,"LastName":"Sarducci","FirstName":"Guido","RecordType":{"Name":"Patient","DeveloperName":"PJN_Patient","Id":"' + patient.RecordTypeId + '"}},"contactInfoByExtIdByRecType":{},"licensesByAddressNetworkId":{},"licensesWithoutAddress":[],"parentAccounts":[],"searchUtilityClass":"PJN_AccountSearchHdlr"}';
        Case updatedCase;

        Test.startTest();
        updatedCase = PJN_AccountSearchLightningUtil.selectAccount(carePlan, original);
        Test.stopTest();

        System.assertNotEquals(null, updatedCase, 'Should return a case');
        System.assertEquals(carePlan.Id, updatedCase.Id, 'Should return the same case provided');
        System.assertEquals(patient.Id, updatedCase.AccountId,
            'Should update the case provided');
    }

    @isTest static void testUpdateCase() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        PJN_Contact_Information__c physicianAddress = constructAddress();
        insert physicianAddress;
        activity.PJN_Enrollment_Address__c = physicianAddress.Id;
        Case updatedCase;

        Test.startTest();
        updatedCase = PJN_AccountSearchLightningUtil.updateCase(activity);
        Test.stopTest();

        System.assertNotEquals(null, updatedCase, 'Should return a case');
        System.assertEquals(activity.Id, updatedCase.Id, 'Should return the same case provided');
        System.assertEquals(physicianAddress.Id, updatedCase.PJN_Enrollment_Address__c,
            'Should update the case provided');
    }

    @isTest static void testGetAccountCreationFields() {
        Map<Id, List<PJN_New_Account_Fields_Setting__mdt>> accountFields;
        Test.startTest();
        accountFields = PJN_AccountSearchLightningUtil.getAccountCreationFields();
        Test.stopTest();

        System.assert(accountFields.keySet().size() > 0, 'Should have returned account fields');
    }

    @isTest static void testGetContactInfoCreationFields() {
        Map<String, List<PJN_New_Contact_Info_Fields_Setting__mdt>> infoFields;
        Test.startTest();
        infoFields = PJN_AccountSearchLightningUtil.getContactInfoCreationFields();
        Test.stopTest();

        System.assert(infoFields.keySet().size() > 0, 'Should have returned contact info fields');
    }

    @isTest static void testCreateAccount() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        String patientRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Patient')
            .getRecordTypeId();
        String patientJSON = '{"RecordTypeId":"' + patientRT + '","LastName":"New Patient Account"}';

        String emailRT = Schema.SObjectType.PJN_Contact_Information__c
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Email')
            .getRecordTypeId();
        String phoneRT = Schema.SObjectType.PJN_Contact_Information__c
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Phone')
            .getRecordTypeId();
        String contactInfoJSON ='[';
        contactInfoJSON += '{"RecordTypeId":"' + emailRT + '","PJN_Email__c":"a@b.c"},';
        ContactInfoJSON += '{"RecordTypeId":"' + phoneRT + '","PJN_Phone__c":"8885551212"}]';

        Case updatedCase;
        Test.startTest();
        updatedCase = PJN_AccountSearchLightningUtil.createAccount(
            patientJSON, contactInfoJSON, activity.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, updatedCase, 'Updated case should have been returned');
        System.assertEquals(activity.Id, updatedCase.Id, 'Existing case should have been updated');

        List<Account> newAccounts = [SELECT Id, LastName FROM Account WHERE RecordTypeId = :patientRT ORDER BY CreatedDate DESC];
        System.assertEquals(newAccounts[0].Id, updatedCase.AccountId,
            'Case should be associated with the newly created account');

        List<PJN_Contact_Information__c> newContacts = [
            SELECT Id, RecordTypeId, PJN_Account__c, PJN_Email__c
            FROM PJN_Contact_Information__c
            WHERE PJN_Account__c = :newAccounts[0].Id
        ];
        System.assertEquals(2, newContacts.size(),
            'Incorrect number of new contact information records created');

        for(PJN_Contact_Information__c ci : newContacts) {
            System.assertEquals(
                String.isBlank(ci.PJN_Email__c) ? phoneRT : emailRT,
                ci.RecordTypeId,
                'Incorrect record type utilized');
        }
    }

    @isTest static void testGetAddresses() {
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        PJN_TestFactoryContactInformation contactInfoFactory = new PJN_TestFactoryContactInformation();
        List<PJN_Contact_Information__c> addresses = new List<PJN_Contact_Information__c>();

        String country = PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue();
        addresses.add(contactInfoFactory.constructAddress
            (patient.Id, '123 Main St', null, 'Tampa', null, country, '12345' ));
        addresses.add(contactInfoFactory.constructAddress
            (patient.Id, '345 Broward Ave', null, 'Tampa', null, country, '12345' ));
        addresses.add(contactInfoFactory.constructAddress
            (patient.Id, '678 Wayward Way', null, 'Tampa', null, country, '12345' ));
        insert addresses;

        List<PJN_Contact_Information__c> patientAddresses;
        Test.startTest();
        patientAddresses = PJN_AccountSearchLightningUtil.getAddresses(patient.Id);
        Test.stopTest();

        System.assertEquals(3, patientAddresses.size(), 'Incorrect number of patient addresses');
    }

    @isTest static void testGetContactInfoRecordTypeId() {
        for (RecordType ciRecType : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType='PJN_Contact_Information__c'
            ]) {

            System.assertEquals(
                ciRecType.Id,
                PJN_AccountSearchLightningUtil.getContactInfoRecordTypeId(ciRecType.DeveloperName),
                'Incorrect record type returned for ' + ciRecType.DeveloperName
            );
        }
    }

    @isTest static void testSetPhysicianAddress() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        PJN_Contact_Information__c address = constructAddress();
        insert address;
        Boolean successful = false;

        Test.startTest();
        successful = PJN_AccountSearchLightningUtil.setPhysicianAddress(activity.Id, address.Id);
        Test.stopTest();

        System.assert(successful, 'Primary address should have been successfully set');

        Case tester = [SELECT Id, PJN_Enrollment_Address__c FROM Case WHERE Id= :activity.Id LIMIT 1];
        System.assertEquals(address.Id, tester.PJN_Enrollment_Address__c,
            'Primary address should have been populated on case');
    }

    @isTest static void testSetNewPhysicianAddress() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activity = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        PJN_Contact_Information__c address = constructAddress();
        Boolean successful = false;

        Test.startTest();
        successful = PJN_AccountSearchLightningUtil.setNewPhysicianAddress(activity.Id, address);
        Test.stopTest();

        System.assert(successful, 'New address should have been successfully created and set');

        Case tester = [SELECT Id, PJN_Enrollment_Address__c FROM Case WHERE Id= :activity.Id LIMIT 1];
        System.assertNotEquals(null, tester.PJN_Enrollment_Address__c,
            'New address should have been populated on case');
    }

    @isTest static void testGetPicklistValues() {
        List<Map<String, String>> values;

        Test.startTest();
        values = PJN_AccountSearchLightningUtil.getPicklistValues(
            'PJN_Contact_Information__c',
            'PJN_Country__c'
        );
        Test.stopTest();

        System.assertNotEquals(null, values, 'Picklist map should have been returned');
        System.assert(values.size() > 0, 'Picklist options should have been returned');
    }

    static PJN_Contact_Information__c constructAddress() {
        Id physicianRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account physician = [SELECT Id FROM Account WHERE RecordTypeId = :physicianRTId LIMIT 1];
        PJN_TestFactoryContactInformation contactInfoFactory = new PJN_TestFactoryContactInformation();
        String country = PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue();
        return contactInfoFactory
                    .constructAddress(physician.Id, '123 Main St', null, 'Tampa', null, country, '12345' );
    }

    @isTest static void testGetFieldUpdateability() {
        Test.startTest();
        System.assert(!PJN_AccountSearchLightningUtil.getFieldUpdateability('Case').get('Id'));
        Test.stopTest();
    }

    @isTest static void testGetConfiguredCaseFieldMapByAccountRecType() {
        Test.startTest();
        System.assertEquals('AccountId', PJN_AccountSearchLightningUtil.getConfiguredCaseFieldMapByAccountRecType().get('PJN_Patient'));
        Test.stopTest();
    }

    @isTest static void testGetCreatableRecordTypes() {
        Test.startTest();
        System.assertNotEquals(null, PJN_AccountSearchLightningUtil.getCreatableRecordTypes());
        Test.stopTest();
    }
}