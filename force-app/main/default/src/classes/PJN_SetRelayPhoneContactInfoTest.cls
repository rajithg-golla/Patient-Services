/*
 * Unit tests for PJN_SetRelayPhoneContactInfo
 * @author  Mavens
 * @date    Oct 2021 
 * @group   Relay Network
 */
@isTest(isParallel=false)
public class PJN_SetRelayPhoneContactInfoTest {

    @TestSetup
    static void makeData(){
        List<Account> accounts = new List<Account>();
        for (Integer i=0; i<200; i++) {
            accounts.add(new Account(LastName = 'LastName' + i));
        }
        insert accounts;
    }

    static {
        Relay.testMetaData = new Relay_Network__mdt(
                Client_ID__c='sf-unit=test', 
                API_Key__c='111-222-333', 
                RelayApiUrl__c='https://sf-unit-test.relayit.com');
    }
    
    @isTest
    private static void itShouldSetRelayPhoneOnInsert() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<PJN_Contact_Information__c> phones = new List<PJN_Contact_Information__c>();

        for (Account acct : accounts) {
            phones.add(
                new PJN_Contact_Information__c(
                    RecordTypeId = SObjectType.PJN_Contact_Information__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('PJN_Phone')
                        .getRecordTypeId(),
                    PJN_Account__c = acct.Id,
                    PJN_Set_As_Relay_Phone__c = true
                )
            );
        }

        Test.startTest();
        insert phones;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Account WHERE PJN_Relay_Phone__c IN :phones]);
        System.assertEquals(200,
            [SELECT COUNT()
            FROM PJN_Contact_Information__c
            WHERE PJN_Set_as_Relay_Phone__c = false
            AND PJN_Is_Relay_Phone__c = true
        ]);
    }

    @isTest
    private static void itShouldSetRelayPhoneOnUpdate() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<PJN_Contact_Information__c> phones = new List<PJN_Contact_Information__c>();

        for (Account acct : accounts) {
            phones.add(
                new PJN_Contact_Information__c(
                    RecordTypeId = SObjectType.PJN_Contact_Information__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('PJN_Phone')
                        .getRecordTypeId(),
                    PJN_Account__c = acct.Id,
                    PJN_Set_As_Relay_Phone__c = false
                )
            );
        }
        insert phones;

        for (PJN_Contact_Information__c phone : phones) {
            phone.PJN_Set_As_Relay_Phone__c = true;
        }

        Test.startTest();
        update phones;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Account WHERE PJN_Relay_Phone__c IN :phones]);
        System.assertEquals(200,
            [SELECT COUNT()
            FROM PJN_Contact_Information__c
            WHERE PJN_Set_as_Relay_Phone__c = false
            AND PJN_Is_Relay_Phone__c = true
        ]);
    }

    @isTest
    private static void itShouldErrorIfNotPhone() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
                    RecordTypeId = SObjectType.PJN_Contact_Information__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('PJN_Email')
                        .getRecordTypeId(),
                    PJN_Account__c = account.Id,
                    PJN_Set_As_Relay_Phone__c = true
                );

        Exception caughtException;
        Test.startTest();
            try {
                insert contactInfo;
            } catch(Exception ex) {
                caughtException = ex;
            }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'No error caught');
        System.assert(caughtException.getMessage().contains(PJN_SetRelayPhoneContactInfo.notPhoneRelayError), 'Incorrect error message');
        
    }
}