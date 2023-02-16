/**
 * @author      Mavens
 * @group       PrimaryCIChangeHdlrMVN
 * @description Unit tests for PrimaryCIChangeHdlrMVN
 */
@isTest(isParallel=true)
public with sharing class PrimaryCIChangeHdlrTestMVN {
    
    private static final Integer DATA_SIZE = 200;

    @TestSetup
    static void makeData(){
        Id progParticipantRecTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId();
        Id businessRecTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();

        List<Account> newAccounts = new List<Account>();
        for (Integer i=0; i<DATA_SIZE; i++) {
            newAccounts.add(
                new Account(
                    LastName = 'Test'+i,
                    RecordTypeId = progParticipantRecTypeId
                )
            );
            newAccounts.add(
                new Account(
                    Name = 'Test Business ' + i,
                    RecordTypeId = businessRecTypeId
                )
            );
        }
        insert newAccounts;
    }

    static {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> {
            SObjectType.Account.getSObjectType() => new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PrimaryCIChangeHdlrMVN',
                    PJN_Event__c = 'BEFORE_INSERT',
                    PJN_SObject_API_Name__c = 'Account'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PrimaryCIChangeHdlrMVN',
                    PJN_Event__c = 'BEFORE_UPDATE',
                    PJN_SObject_API_Name__c = 'Account'
                )
            }
        };
    }

    /*** EMAIL TESTS ***/
    @isTest
    private static void itShouldCopyPrimaryEmailToAccountOnInsert() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> emails = createEmailsFor(progParticipants);
        
        Test.startTest();
        insert emails;
        Test.stopTest();

        progParticipants = [SELECT PersonEmail FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('testemail@regneron.test', participant.PersonEmail);
        }
    }

    @isTest
    private static void itShouldCopyPrimaryEmailToAccountOnUpdate() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> emails = createEmailsFor(progParticipants);
        
        insert emails;
        for (PJN_Contact_Information__c email : emails) {
            if (email.PJN_Email__c == 'testemail-1@regneron.test') {
                email.PJN_Set_as_Primary__c = true;
            }
        }
        Test.startTest();
        update emails;
        Test.stopTest();

        progParticipants = [SELECT PersonEmail FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('testemail-1@regneron.test', participant.PersonEmail);
        }
    }

    private static List<PJN_Contact_Information__c> createEmailsFor(List<Account> accounts) {
        Id emailRecTypeIid = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId();
        List<PJN_Contact_Information__c> emails = new List<PJN_Contact_Information__c>();
        for (Account acct : accounts) {
            emails.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = acct.Id,
                    PJN_Set_as_Primary__c = true,
                    PJN_Email__c = 'testemail@regneron.test',
                    RecordTypeId = emailRecTypeIid
                ) 
            );
            emails.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = acct.Id,
                    PJN_Set_as_Primary__c = false,
                    PJN_Email__c = 'testemail-1@regneron.test',
                    RecordTypeId = emailRecTypeIid
                )
            );
        }
        return emails;
    }

    /*** Phone/Fax Tests ***/
    @isTest
    private static void itShouldCopyPrimaryPhoneToAccountOnInsert() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> phones = createPhonesFor(progParticipants, 'PJN_Phone');
        
        Test.startTest();
        insert phones;
        Test.stopTest();

        progParticipants = [SELECT Phone FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('5555555555', participant.Phone);
        }
    }

    @isTest
    private static void itShouldCopyPrimaryPhoneToAccountOnUpdate() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> phones = createPhonesFor(progParticipants, 'PJN_Phone');
        
        insert phones;
        for (PJN_Contact_Information__c phone : phones) {
            if (phone.PJN_Phone__c == '6666666666') {
                phone.PJN_Set_as_Primary__c = true;
            }
        }
        Test.startTest();
        update phones;
        Test.stopTest();

        progParticipants = [SELECT Phone FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('6666666666', participant.Phone);
        }
    }

    @isTest
    private static void itShouldCopyPrimaryFaxToAccountOnInsert() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> faxes = createPhonesFor(progParticipants, 'PJN_Fax');
        
        Test.startTest();
        insert faxes;
        Test.stopTest();

        progParticipants = [SELECT Fax FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('5555555555', participant.Fax);
        }
    }

    @isTest
    private static void itShouldCopyPrimaryFaxToAccountOnUpdate() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> faxes = createPhonesFor(progParticipants, 'PJN_Fax');
        
        insert faxes;
        for (PJN_Contact_Information__c fax : faxes) {
            if (fax.PJN_Fax__c == '6666666666') {
                fax.PJN_Set_as_Primary__c = true;
            }
        }
        Test.startTest();
        update faxes;
        Test.stopTest();

        progParticipants = [SELECT Fax FROM Account WHERE Id IN :progParticipants];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assertEquals('6666666666', participant.Fax);
        }
    }

    private static List<PJN_Contact_Information__c> createPhonesFor(List<Account> accounts, String recTypeDevName) {
        Id phoneRecTypeIid = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        List<PJN_Contact_Information__c> phones = new List<PJN_Contact_Information__c>();
        for (Account acct : accounts) {
            phones.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = acct.Id,
                    PJN_Set_as_Primary__c = true,
                    PJN_Phone__c = '5555555555',
                    PJN_Fax__c = '5555555555',
                    RecordTypeId = phoneRecTypeIid
                ) 
            );
            phones.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = acct.Id,
                    PJN_Set_as_Primary__c = false,
                    PJN_Phone__c = '6666666666',
                    PJN_Fax__c = '6666666666',
                    RecordTypeId = phoneRecTypeIid
                )
            );
        }
        return phones;
    }

    /*** Address Tests ***/
    @isTest
    private static void itShouldCopyPrimaryAddressToPersonAccount() {
        List<Account> progParticipants = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Program_Participant_MVN'];
        List<PJN_Contact_Information__c> addresses = createAddressesFor(progParticipants);
        
        Test.startTest();
        insert addresses;
        Test.stopTest();

        progParticipants = [
            SELECT PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry 
            FROM Account 
            WHERE Id IN :progParticipants            
        ];
        System.assertEquals(DATA_SIZE, progParticipants.size());
        for (Account participant : progParticipants) {
            System.assert(participant.PersonMailingStreet.contains('123 Main St.'));
            System.assert(participant.PersonMailingStreet.contains('Suite 1'));
            System.assertEquals('Tarrytown', participant.PersonMailingCity);
            System.assertEquals('NY', participant.PersonMailingState);
            System.assertEquals('22222', participant.PersonMailingPostalCode);
            System.assertEquals('United States', participant.PersonMailingCountry);
        }
    }

    @isTest
    private static void itShouldCopyPrimaryAddressToBusinessAccount() {
        List<Account> businesses = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'IndustriesBusiness'];
        List<PJN_Contact_Information__c> addresses = createAddressesFor(businesses);
        
        Test.startTest();
        insert addresses;
        Test.stopTest();

        businesses = [
            SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account 
            WHERE Id IN :businesses
        ];
        System.assertEquals(DATA_SIZE, businesses.size());
        for (Account business : businesses) {
            System.assert(business.BillingStreet.contains('123 Main St.'));
            System.assert(business.BillingStreet.contains('Suite 1'));
            System.assertEquals('Tarrytown', business.BillingCity);
            System.assertEquals('NY', business.BillingState);
            System.assertEquals('22222', business.BillingPostalCode);
            System.assertEquals('United States', business.BillingCountry);
        }
    }


    private static List<PJN_Contact_Information__c> createAddressesFor(List<Account> accounts) {
        Id addrRecordtypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId();
        List<PJN_Contact_Information__c> addresses = new List<PJN_Contact_Information__c>();
        for (Account acct : accounts) {
            addresses.add(
                new PJN_Contact_Information__c(
                    PJN_Account__c = acct.Id,
                    PJN_Set_as_Primary__c = true,
                    PJN_Address_Line_1__c = '123 Main St.',
                    PJN_Address_Line_2__c = 'Suite 1.',
                    PJN_City__c = 'Tarrytown',
                    PJN_State__c = 'NY',
                    PJN_Postal_Code__c = '22222',
                    PJN_Country__c = 'United States',
                    RecordTypeId = addrRecordtypeId
                ) 
            );
        }
        return addresses;
    }
}