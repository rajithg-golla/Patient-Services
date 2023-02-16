@isTest
public class EmailTemplatePreviewCtrlTestMVN {
    
    @isTest
    private static void itShouldReturnTemplateInfo() {
        EnhancedLetterHead lh = new EnhancedLetterHead(
            Name = 'Test LetterHead',
            LetterHeadHeader = '<img src="image.com"/>',
            LetterheadFooter = '<img src="image.com"/>'
        );
        insert lh;

        EmailTemplate et = new EmailTemplate(
            Name = 'Test Template',
            EnhancedLetterheadId = lh.Id,
            DeveloperName = 'Test_Template_Dev_Name',
            HtmlValue = '<div> {{{Recipient.FirstName}}} body text</div>',
            FolderId = UserInfo.getUserId(),
            isActive = true,
            TemplateType = 'custom',
            UiType = 'SFX'
        );
        insert et;

        EmailTemplate returnedTemplate;
        Test.startTest();
        returnedTemplate = EmailTemplatePreviewCtrlMVN.getTemplateByDevelopername('Test_Template_Dev_Name');
        Test.stopTest();

        System.assertEquals(et.HtmlValue, returnedTemplate.HtmlValue);
        System.assertEquals(lh.LetterheadHeader, returnedTemplate.EnhancedLetterHead.LetterheadHeader);
        System.assertEquals(lh.LetterheadFooter, returnedTemplate.EnhancedLetterHead.LetterHeadFooter);
    }
}