/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Unit tests for LeadConvertReparentChildrenMVN
 *              assumes configuration is correct for metadata 
 */
@isTest
public class LeadConvertReparentChildrenTestMVN {
    
    private static final Integer DATA_SIZE = 200;

    static {
        // don't need to actually end emails in the test
        EmailQuickSendHdlrMVN.sendEmails = false;
    }
    
    @TestSetup
    static void makeData() {
        String firstTemplateValue = SObjectType.Email_Quick_Send_MVN__c
            .fields.getMap()
            .get('Email_Template_MVN__c')
            .getDescribe()
            .getPicklistValues()[0]
            .getValue();

        if ([SELECT Id FROM EmailTemplate WHERE DeveloperName = :firstTemplateValue].isEmpty()) {
            System.runAs(new User(Id= UserInfo.getUserId())) {
                EmailTemplate testTemplate = new EmailTemplate(
                    DeveloperName = 'TestTemplate_MVN',
                    HtmlValue = '<html><body>test</body></html>',
                    Description = 'Test Template',
                    Encoding = 'ISO-8859-1',
                    Name = 'Test Template',
                    Subject = 'Test Template',
                    IsActive = true,
                    TemplateType = 'Custom',
                    FolderId = userInfo.getUserId()
                );
        
                insert testTemplate;
            }
        }

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
        
        List<Email_Quick_Send_MVN__c> emails = new List<Email_Quick_Send_MVN__c>();               

        for (Lead ld : leads) {
            emails.add(
                new Email_Quick_Send_MVN__c (
                    Consumer_MVN__c = ld.Id,
                    To_Address_MVN__c = 'test@consumer.com', 
                    From_Address_MVN__c = 'DEDSI Program',
                    Email_Template_MVN__c = firstTemplateValue
                )
            );
        }
        insert emails;

        List<Database.LeadConvert> converts = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

        for (Lead ld : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            converts.add(lc);
        }
        Database.convertLead(converts);
    }

    @isTest
    private static void itShouldReparentRecordsFromConvertedLeadToAccountAndCarePlan() {
        List<Lead> leads = [SELECT Id, ConvertedAccountId FROM Lead];
        List<Case> carePlans = new List<Case>(); 
        for (Lead ld : leads) {
            carePlans.add(
                new Case (
                    AccountId = ld.ConvertedAccountId,
                    RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
                )
            );
        }

        insert carePlans;

        Test.startTest();
        LeadConvertReparentChildrenMVN.reparentLeadChidren(new List<Id>(new Map<Id, Case>(carePlans).keySet()));
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [
            SELECT COUNT()
            FROM Email_Quick_Send_MVN__c
            WHERE Account_MVN__c != null
            AND Care_Plan_MVN__c != null
        ]);
                
    }

}