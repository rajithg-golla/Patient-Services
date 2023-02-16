/**
 * @author      Mavens
 * @group       EmailQuickSend
 * @description Unit tests for EmailQuickSend
 */
@isTest
public class EmailQuickSendHdlrTestMVN {
    
    private static final Integer DATA_SIZE = 200;
    static {
        EmailQuickSendHdlrMVN.sendEmails = false;
    }

    @TestSetup
    static void makeData(){
        List<Lead> leads = new List<Lead>();
        List<Account> accounts = new List<Account>();
        Campaign event = new Campaign(Name='Test');
        insert event;
        
        for (Integer i=0; i<DATA_SIZE; i++) {
            leads.add(
                new Lead(
                    Event_MVN__c=event.Id,
                    LastName='Test'+i,
                    Phone = '5555555555',
                    Status = 'Consented'
                )
            );

            accounts.add(                
                new Account(
                    LastName = 'Test Account' + i,
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
                )
            );
        }

        insert leads;
        insert accounts;

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
    }

    @isTest
    private static void itShouldSendEmailsToLeads() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Email_Quick_Send_MVN__c> emails = new List<Email_Quick_Send_MVN__c>();
        String firstTemplateValue = SObjectType.Email_Quick_Send_MVN__c
            .fields.getMap()
            .get('Email_Template_MVN__c')
            .getDescribe()
            .getPicklistValues()[0]
            .getValue();

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
    }

    @isTest
    private static void itShouldSendEmailsAccountss() {
        List<Account> accounts =[SELECT Id FROM Account];
        List<Email_Quick_Send_MVN__c> emails = new List<Email_Quick_Send_MVN__c>();
        String firstTemplateValue = SObjectType.Email_Quick_Send_MVN__c
            .fields.getMap()
            .get('Email_Template_MVN__c')
            .getDescribe()
            .getPicklistValues()[0]
            .getValue();
            
        for (Account acct : accounts) {
            emails.add(
                new Email_Quick_Send_MVN__c (
                    Account_MVN__c = acct.Id,
                    To_Address_MVN__c = 'test@consumer.com', 
                    From_Address_MVN__c = 'DEDSI Program',
                    Email_Template_MVN__c = firstTemplateValue
                )
            );
        }
        insert emails;
    }
}