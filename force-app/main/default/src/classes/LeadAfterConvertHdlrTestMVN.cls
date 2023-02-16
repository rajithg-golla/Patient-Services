/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Unit tests for LeadAfterConvertHdlrMVN
 */

@isTest(isParallel=true)
public class LeadAfterConvertHdlrTestMVN {
    private static final Integer DATA_SIZE = 150;

    @TestSetup
    static void makeData() {
        Campaign event = new Campaign(Name='Test');
        insert event;

        List<Lead> leads = new List<Lead>();

        for (Integer i=0; i < DATA_SIZE; i++) {
            leads.add(
                new Lead(
                    Event_MVN__c=event.Id,
                    LastName='Test'+i,
                    Phone = '5555555555',
                    Status = 'Consented'
                )
            );
        }
        insert leads;
    }

     /*
     * Test that converted leads trigger creation of contact information
     */
    @isTest
    private static void itShouldCreateContactInformation() {
        List<Lead> leads = [SELECT Id, Email, Phone, Street, City, State, PostalCode, Country FROM Lead];
        for (Lead ld : leads) {
            ld.Phone = '5555555555';
            ld.Email = 'test@test.com';
            ld.Street = '123 Main St.';
            ld.City = 'Somewhere';
            ld.State = 'NY';
            ld.PostalCode = '10101';
            ld.Country = 'United States';
        }
        update leads;

        List<Database.LeadConvert> converts = prepareLeadConversions(leads);

        Test.startTest();
        List<Database.LeadConvertResult> lcr = Database.convertLead(converts);
        Test.stopTest();

        List<PJN_Contact_Information__c> phones = [
            SELECT PJN_Phone__c FROM PJN_Contact_Information__c WHERE RecordType.DeveloperName = 'PJN_Phone'
        ];
        System.assertEquals(DATA_SIZE, phones.size());
        for (PJN_Contact_Information__c phone :phones) {
            System.assertEquals('5555555555',phone.PJN_Phone__c);
        }

        List<PJN_Contact_Information__c> emails = [
            SELECT PJN_Email__c FROM PJN_Contact_Information__c WHERE RecordType.DeveloperName = 'PJN_email'
        ];
        System.assertEquals(DATA_SIZE, emails.size());
        for (PJN_Contact_Information__c email :emails) {
            System.assertEquals('test@test.com',email.PJN_Email__c);
        }

        List<PJN_Contact_Information__c> addresses = [
            SELECT PJN_Address_Line_1__c, PJN_City__c, PJN_State__c, PJN_Postal_Code__c, PJN_Country__c
            FROM PJN_Contact_Information__c
            WHERE RecordType.DeveloperName = 'PJN_Address'
        ];
        System.assertEquals(DATA_SIZE, addresses.size());
        for (PJN_Contact_Information__c address : addresses) {
            System.assertEquals('123 Main St.', address.PJN_Address_Line_1__c);
            System.assertEquals('Somewhere', address.PJN_City__c);
            System.assertEquals('NY', address.PJN_State__c);
            System.assertEquals('10101', address.PJN_Postal_Code__c);
            System.assertEquals('United States', address.PJN_Country__c);
        }
    }

    /*
     * prepare a list of lead convert objects from the list of leads
     */
    private static List<Database.LeadConvert> prepareLeadConversions(List<Lead> leads) {
        List<Database.LeadConvert> converts = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

        for (Lead ld : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            converts.add(lc);
        }

        return converts;
    }
}