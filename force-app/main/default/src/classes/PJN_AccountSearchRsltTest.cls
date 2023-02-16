@isTest(isParallel=true) private class PJN_AccountSearchRsltTest {

    private static Map<String, RecordTypeInfo> ciRtInfos = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName();

    @testSetup private static void setup() {
        Account accountRecord = new Account(
            FirstName = 'Jimmy',
            LastName = 'Hendrix'
        );
        insert accountRecord;


        List<PJN_Contact_Information__c> ciRecords = new List<PJN_Contact_Information__c> {
            new PJN_Contact_Information__c(
                PJN_Account__c = accountRecord.Id,
                PJN_Set_as_Primary__c = true,
                RecordTypeId = ciRtInfos.get('PJN_Address').getRecordTypeId()
            ),
            new PJN_Contact_Information__c(
                PJN_Account__c = accountRecord.Id,
                PJN_Set_as_Primary__c = true,
                PJN_Phone__c = '5555555555',
                PJN_Veeva_Network_Id__c = '09874',
                RecordTypeId = ciRtInfos.get('PJN_Phone').getRecordTypeId()
            )
        };
        insert ciRecords;
    }

    @isTest private static void itShouldConstructAnAccountSearchResultWithContactInfo() {
        Account acct = [SELECT Id, LastName, HealthCloudGA__SourceSystemId__c, PJN_Veeva_Network_Id__c FROM Account LIMIT 1];
        System.assertEquals(acct.LastName, 'Hendrix');

        List<PJN_Contact_Information__c> ciRecords = [
            SELECT Id, RecordTypeId, PJN_External_Id__c, PJN_Veeva_Network_Id__c FROM PJN_Contact_Information__c WHERE PJN_Account__c = :acct.Id
        ];

        Test.startTest();
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            acct,
            ciRecords,
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );
        Test.stopTest();

        System.assertEquals(rslt.accountDetail, acct);
        System.assertEquals(rslt.contactInfoByExtIdByRecType.size(), 2);
        System.assertEquals(rslt.getContactInfoRecords().size(), 2);
        System.assertEquals(rslt.contactInfoByNetworkId.size(), 2);

        rslt.ParentAccounts = new List<PJN_AccountSearchRslt>{rslt.clone()};

        System.assertEquals(rslt.allParentContactInfoByNetworkId.size(), 2);
    }

    @isTest private static void itShouldConstructAnAccountSearchResultWithOutContactInfo() {
        Account acct = [SELECT Id, LastName, HealthCloudGA__SourceSystemId__c, PJN_Veeva_Network_Id__c FROM Account LIMIT 1];

        Test.startTest();
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            acct,
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );
        Test.stopTest();

        System.assertEquals(rslt.accountDetail, acct);
    }

    @isTest private static void itShouldReturnTheCorrectAccountIdentifier() {
        Account acct = [SELECT Id, LastName, HealthCloudGA__SourceSystemId__c, PJN_Veeva_Network_Id__c FROM Account LIMIT 1];

        Test.startTest();
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            acct,
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );
        System.assertEquals(rslt.getAccountIdentifier(), acct.Id);
        rslt.accountDetail.PJN_Veeva_Network_Id__c = '12345';
        System.assertEquals(rslt.getAccountIdentifier(), '12345');
        Test.stopTest();
    }

    @isTest private static void itShouldReturnCorrectContactInfoIdentifier() {
        List<PJN_Contact_Information__c> ciRecords = [
            SELECT Id, RecordTypeId, PJN_External_Id__c, PJN_Veeva_Network_Id__c
            FROM PJN_Contact_Information__c
            ORDER BY PJN_Veeva_Network_Id__c NULLS LAST
        ];

        System.assertEquals(ciRecords.size(), 2);
        System.assert(String.isNotBlank(ciRecords[0].PJN_Veeva_Network_Id__c));
        System.assert(String.isBlank(ciRecords[1].PJN_Veeva_Network_Id__c));

        // just need a reslt to pass data to for this test
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            new Account(),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        Test.startTest();
        System.assertEquals(rslt.getContactInfoIdentifier(ciRecords[0]), '09874');
        System.assertEquals(rslt.getContactInfoIdentifier(ciRecords[1]), ciRecords[1].Id);

        rslt.addContactInfoRecords(ciRecords);

        System.assertEquals(rslt.getContactInfoForRecordType(ciRtInfos.get('PJN_Fax').getRecordTypeId()).size(), 0);
        System.assertEquals(rslt.getContactInfoForRecordType(ciRtInfos.get('PJN_Address').getRecordTypeId()).size(), 1);
        System.assertEquals(rslt.getContactInfoForRecordType(ciRtInfos.get('PJN_Phone').getRecordTypeId()).size(), 1);
        Test.stopTest();
    }

    @isTest private static void itShouldReturnRightDisplayValue() {
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            new Account(),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        // last two params (object and field name) only matter for boolen values
        System.assertEquals(rslt.getDisplayValue(null, DisplayType.Date, 'PersonDoNotCall', 'Account'), '');
        Date today = Date.today();
        System.assertEquals(rslt.getDisplayValue(today, DisplayType.Date, 'PersonDoNotCall', 'Account'), today.format());
        DateTime now = DateTime.now();
        System.assertEquals(rslt.getDisplayValue(now, DisplayType.DateTime, 'PersonDoNotCall', 'Account'), now.format());
        Boolean yes = true;
        System.assertEquals(rslt.getDisplayValue(yes, DisplayType.Boolean, 'PersonDoNotCall', 'Account'), 'Do Not Call');
        System.assertEquals(rslt.getDisplayValue('A String', DisplayType.String, 'PersonDoNotCall', 'Account'), 'A String');
    }

    @isTest private static void itShouldReturnSingleResultByField() {
        List<PJN_FieldWrapper> wrappers = new List<PJN_FieldWrapper>{
            new PJN_FieldWrapper(
                new PJN_Field_Setting__mdt (
                    PJN_Object__c = 'Account',
                    PJN_Field__c = 'LastName'
                )
            ),
            new PJN_FieldWrapper(
                new PJN_Field_Setting__mdt (
                    PJN_Object__c = 'PJN_Contact_Information__c',
                    PJN_Field__c = 'PJN_Phone__c',
                    PJN_Contact_Info_Record_Type__c = 'PJN_Phone'
                )
            ),
            new PJN_FieldWrapper(
                new PJN_Field_Setting__mdt (
                    PJN_Object__c = 'Case',
                    PJN_Field__c = 'Subject'
                )
            )
        };

        Account acct = [SELECT Id FROM Account LIMIT 1];
        List<PJN_Contact_Information__c> ciRecords = [
            SELECT Id, RecordTypeId, PJN_External_Id__c, PJN_Veeva_Network_Id__c, PJN_Phone__c FROM PJN_Contact_Information__c WHERE PJN_Account__c = :acct.Id
        ];

        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;

        Case carePlan = new Case (
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Subject = 'Test',
            AccountId = acct.Id,
            PJN_Program__c = program.Id,
            PJN_Program_DeveloperName__c = program.PJN_Program_DeveloperName__c
        );
        insert carePlan;
        acct = [
            SELECT Id, LastName, RecordTypeId, RecordType.Name, HealthCloudGA__SourceSystemId__c, RecordType.DeveloperName, PJN_Veeva_Network_Id__c, (SELECT Subject FROM Cases)
            FROM Account LIMIT 1
        ];
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            acct,
            ciRecords,
            'SomeClass',
            wrappers
        );

        Test.startTest();
        rslt.setSingleResultByField(wrappers);
        Test.stopTest();

        System.assertEquals('Hendrix', rslt.singleResultByField.get('AccountLastName'));
        System.assertEquals('5555555555', rslt.singleResultByField.get('PJN_Contact_Information__cPJN_Phone__c'));
        System.assertEquals('Test', rslt.singleResultByField.get('CaseSubject'));
    }

    @isTest private static void itShouldCompareCorrectly() {
         PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            new Account(LastName = 'Smith', FirstName = 'John'),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        PJN_AccountSearchRslt rslt2 = new PJN_AccountSearchRslt (
            new Account(LastName = 'Smith', FirstName = 'John'),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        System.assertEquals(0, rslt.compareTo(rslt2));
        rslt2.accountDetail.FirstName = 'Abe';
        System.assert(rslt.compareTo(rslt2) > 0);
        rslt2.accountDetail.FirstName = 'Mickey';
        System.assert(rslt.compareTo(rslt2) < 0);
        rslt2.accountDetail.LastName = 'Tanger';
        System.assert(rslt.compareTo(rslt2) < 0);

        rslt = new PJN_AccountSearchRslt (
            new Account(Name = 'Acme'),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        rslt2 = new PJN_AccountSearchRslt (
            new Account(Name = 'Clacme'),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );
        System.assert(rslt.compareTo(rslt2) < 0);
    }

    @isTest private static void itShouldAllowNetorkAdditionsAndRetrievals() {
        PJN_AccountSearchRslt rslt = new PJN_AccountSearchRslt (
            new Account(LastName = 'Smith', FirstName = 'John'),
            'SomeClass',
            new List<PJN_FieldWrapper>()
        );

        rslt.addParentAccounts(new List<PJN_AccountSearchRslt>());
        System.assert(rslt.getParentAccounts().isEmpty());
        System.assert(rslt.getAllParentContactInfo().isEmpty());
        rslt.addLicenses(new Map<String, PJN_License__c> ());
        System.assert(rslt.getLicensesByNetworkId().isEmpty());
        rslt.addAffiliations(new Map<String, PJN_Affiliation__c>());
        System.assert(rslt.getAffiliationsByNetworkId().isEmpty());
    }
}